import { env } from "@bin/tub-server";
import apn from "@parse/node-apn";
import { GqlClient } from "@tub/gql";
import { Mutex } from "async-mutex";
import path, { dirname } from "path";
import { fileURLToPath } from "url";
import { Config } from "./ConfigService";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Data structure for tracking push notification state
 */
type PushItem = {
  tokenMint: string; // Token mint address
  initialPriceUsd: string; // Initial price when tracking started
  deviceToken: string; // Device push token
  timestamp: number; // Registration timestamp
};

/**
 * Service that manages live price tracking and push notifications for tokens
 * Handles subscription lifecycle and batched push notification delivery
 */
export class PushService {
  private config: Config;
  private pushRegistry: Map<string, PushItem> = new Map();
  private gqlClient: GqlClient["db"];

  private subscriptions: Map<string, { subscription: { unsubscribe: () => void }; subCount: number }> = new Map();
  private tokenPrice: Map<string, string> = new Map();
  private activityMutex = new Mutex();
  private options = {
    token: {
      key: path.resolve(__dirname, `../utils/AuthKey_${env.APPLE_PUSH_KEY_ID}.p8`),
      keyId: env.APPLE_PUSH_KEY_ID,
      teamId: env.APPLE_PUSH_TEAM_ID,
    },
    production: false,
  };

  private apnProvider = new apn.Provider(this.options);

  /**
   * Creates a new PushService instance
   * @param args.gqlClient - GraphQL client for price subscriptions
   * @param args.config - Service configuration
   */
  constructor(args: { gqlClient: GqlClient["db"]; config: Config }) {
    this.config = args.config;
    this.initializePushes();
    this.gqlClient = args.gqlClient;
  }

  /**
   * Removes stale entries from the push registry based on configured timeout
   */
  private async cleanupRegistry() {
    const now = Date.now();
    for (const [key, value] of this.pushRegistry.entries()) {
      if (now - value.timestamp > this.config.PUSH_REGISTRY_TIMEOUT_MS) {
        this.pushRegistry.delete(key);
        this.cleanSubscription(value.tokenMint);
      }
    }
  }

  /* ------------------------------ Subscriptions ----------------------------- */

  /**
   * Starts or increments subscription count for a token's price updates
   * @param tokenMint - Token mint address to subscribe to
   */
  private beginTokenSubscription(tokenMint: string) {
    if (this.subscriptions.has(tokenMint)) {
      this.subscriptions.get(tokenMint)!.subCount++;
      return;
    }

    const subscription = this.gqlClient
      .GetRecentTokenPriceSubscription({
        token: tokenMint,
      })
      .subscribe((data) => {
        if (!data?.data?.api_trade_history[0]) {
          return;
        }
        this.tokenPrice.set(tokenMint, data.data.api_trade_history[0].token_price_usd);
      });
    console.log("Subscribed to token", tokenMint);

    this.subscriptions.set(tokenMint, { subscription, subCount: 1 });
  }

  /**
   * Decrements subscription count and cleans up if no more subscribers
   * @param tokenMint - Token mint address to unsubscribe from
   */
  private async cleanSubscription(tokenMint: string) {
    const sub = this.subscriptions.get(tokenMint);
    if (!sub) return;

    sub.subCount--;
    if (sub.subCount === 0) {
      sub.subscription.unsubscribe();
      this.subscriptions.delete(tokenMint);
      this.tokenPrice.delete(tokenMint);
    }
  }

  /* --------------------------------- Live activity --------------------------------- */

  /**
   * Registers a new live activity for price tracking
   * @param userId - User identifier
   * @param input.tokenMint - Token mint address to track
   * @param input.tokenPriceUsd - Initial token price in USD
   * @param input.deviceToken - Device push token
   */
  async startLiveActivity(userId: string, input: { tokenMint: string; tokenPriceUsd: string; deviceToken: string }) {
    const release = await this.activityMutex.acquire();
    try {
      if (this.pushRegistry.has(userId)) {
        return;
      }
      this.pushRegistry.set(userId, {
        tokenMint: input.tokenMint,
        initialPriceUsd: input.tokenPriceUsd,
        deviceToken: input.deviceToken,
        timestamp: Date.now(),
      });
      this.beginTokenSubscription(input.tokenMint);
    } finally {
      release();
    }
  }

  /**
   * Stops live activity tracking for a user
   * @param userId - User identifier to stop tracking
   */
  async stopLiveActivity(userId: string) {
    const release = await this.activityMutex.acquire();
    try {
      if (!this.pushRegistry.has(userId)) {
        return;
      }
      const tokenMint = this.pushRegistry.get(userId)!.tokenMint;
      this.pushRegistry.delete(userId);
      this.cleanSubscription(tokenMint);
    } finally {
      release();
    }
  }

  /* --------------------------------- Pushes --------------------------------- */

  /**
   * Initializes periodic cleanup and push notification tasks
   */
  private initializePushes(): void {
    (async () => {
      setInterval(() => this.cleanupRegistry(), this.config.PUSH_CLEANUP_INTERVAL_MS);
      setInterval(() => this.sendAllPushes(), this.config.PUSH_SEND_INTERVAL_MS);
    })();
  }

  /**
   * Sends push notifications in batches to all registered users
   */
  private async sendAllPushes() {
    const BATCH_SIZE = 50;
    const entries = Array.from(this.pushRegistry.entries());

    for (let i = 0; i < entries.length; i += BATCH_SIZE) {
      const batch = entries.slice(i, i + BATCH_SIZE);
      await Promise.all(batch.map(([, value]) => this.sendPush(value)));
    }
  }

  /**
   * Sends a push notification for a specific user
   * @param input - Push notification data
   */
  private async sendPush(input: PushItem) {
    const tokenPrice = this.tokenPrice.get(input.tokenMint);
    if (!tokenPrice) return;

    const notification = new apn.Notification({
      payload: {
        aps: {
          "content-state": {
            currentPriceUsd: parseFloat(tokenPrice),
            timestamp: new Date().toISOString(),
          },
          timestamp: Date.now(),
          event: "update",
        },
      },
    });

    // Required configuration
    notification.topic = `com.primodium.tub.push-type.liveactivity`;
    notification.pushType = "alert";
    notification.expiry = Math.floor(Date.now() / 1000) + 3600; // 1 hour
    notification.priority = 10; // Send immediately

    // Optional: Add collapse ID to group similar notifications
    notification.collapseId = `price_update_${input.tokenMint}`;

    try {
      // todo: group all devices with the same token
      const result = await this.apnProvider.send(notification, input.deviceToken);
      if (result.failed.length > 0) {
        throw new Error(`Push failed: ${result.failed[0]?.response}`);
      }
    } catch (error) {
      console.error(error);
    }
  }
}
