import { env } from "@bin/tub-server";
import apn from "@parse/node-apn";
import { GqlClient } from "@tub/gql";
import { Mutex } from "async-mutex";
import fs from "fs";
import http2 from "http2";
import jwt from "jsonwebtoken";
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
  pushToken: string; // Push token
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

  private session: http2.ClientHttp2Session | null = null;
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

  stop() {
    if (this.session) {
      this.session.close();
      this.session = null;
    }
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
  async startOrUpdateLiveActivity(
    userId: string,
    input: { tokenMint: string; tokenPriceUsd: string; deviceToken: string; pushToken: string },
  ) {
    const release = await this.activityMutex.acquire();
    const existing = this.pushRegistry.get(userId);
    try {
      if (existing && existing.tokenMint !== input.tokenMint) {
        this.cleanSubscription(existing.tokenMint);
        this.beginTokenSubscription(input.tokenMint);
      }
      this.pushRegistry.set(userId, {
        tokenMint: input.tokenMint,
        initialPriceUsd: input.tokenPriceUsd,
        deviceToken: input.deviceToken,
        pushToken: input.pushToken,
        timestamp: Date.now(),
      });
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
    const pushItem = this.pushRegistry.get(userId);
    try {
      if (!pushItem) {
        return;
      }
      this.pushRegistry.delete(userId);
      this.cleanSubscription(pushItem.tokenMint);
      this.sendEndPush(pushItem);
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
      await Promise.all(batch.map(([, value]) => this.sendUpdatePush(value)));
    }
  }

  /**
   * Sends a push notification for a specific user
   * @param input - Push notification data
   */

  private async sendUpdatePush(input: PushItem) {
    const tokenPrice = this.tokenPrice.get(input.tokenMint);
    if (!tokenPrice) return;

    const json = {
      aps: {
        "content-state": {
          currentPriceUsd: parseFloat(tokenPrice),
          timestamp: Math.floor(Date.now() / 1000),
        },
        event: "update",
        timestamp: Math.floor(Date.now() / 1000),
        "relevance-score": 100,
        "stale-date": Math.floor(Date.now() / 1000 + 60 * 60 * 8),
      },
    };

    this.publishToApns(input.pushToken, json);
  }

  private async sendEndPush(input: PushItem) {
    const tokenPrice = this.tokenPrice.get(input.tokenMint);
    if (!tokenPrice) return;

    const json = {
      aps: {
        "content-state": {
          currentPriceUsd: parseFloat(tokenPrice),
          timestamp: Math.floor(Date.now() / 1000),
        },
        event: "end",
        timestamp: Math.floor(Date.now() / 1000),
        "relevance-score": 100,
        "stale-date": Math.floor(Date.now() / 1000 + 60 * 60 * 8),
      },
    };

    this.publishToApns(input.pushToken, json);
  }

  private getSession(): http2.ClientHttp2Session {
    if (!this.session || this.session.destroyed) {
      this.session = http2.connect("https://api.sandbox.push.apple.com:443");
      this.session.on("error", (err) => {
        console.error("Session Error:", err);
        this.session = null; // Allow reconnection on next request
      });
      this.session.on("goaway", () => {
        console.log("Session received GOAWAY, will reconnect on next request");
        this.session = null;
      });
    }
    return this.session;
  }

  private publishToApns(pushToken: string, json: object) {
    console.log(`Token to push: ${pushToken}, payload: ${JSON.stringify(json)}`);

    const privateKey = fs.readFileSync(this.options.token.key);
    const secondsSinceEpoch = Math.round(Date.now() / 1000);
    const payload = {
      iss: this.options.token.teamId,
      iat: secondsSinceEpoch,
    };

    const finalEncryptToken = jwt.sign(payload, privateKey, { algorithm: "ES256", keyid: this.options.token.keyId });

    try {
      const buffer = Buffer.from(JSON.stringify(json));
      const session = this.getSession();

      const req = session.request({
        ":method": "POST",
        ":path": "/3/device/" + pushToken,
        authorization: "bearer " + finalEncryptToken,
        "apns-push-type": "liveactivity",
        "apns-topic": `com.primodium.tub.push-type.liveactivity`,
        "apns-priority": "10",
        "Content-Type": "application/json",
        "Content-Length": buffer.length,
      });

      req.end(buffer);

      req.on("response", (headers) => {
        console.log(headers[http2.constants.HTTP2_HEADER_STATUS]);
      });

      req.on("error", (err) => {
        console.error("Request error:", err);
      });

      let data = "";
      req.setEncoding("utf8");
      req.on("data", (chunk) => (data += chunk));
      req.on("end", () => {
        console.log(`Response: ${data}`);
      });
    } catch (err) {
      console.error("Error sending token:", err);
      this.session?.destroy(); // Force reconnection on next request
    }
  }
}
