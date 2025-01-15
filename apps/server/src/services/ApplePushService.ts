import { GqlClient } from "@tub/gql";
import { Mutex } from "async-mutex";
import http2 from "http2";
import jwt from "jsonwebtoken";
import { env } from "../../bin/tub-server";
import { config } from "../utils/config";
/**
 * Data structure for tracking push notification state
 */
type PushItem = {
  tokenMint: string; // Token mint address
  initialPriceUsd: string; // Initial price when tracking started
  deviceToken: string; // Device push token
  pushToken: string; // Push token
  timestamp: number; // Registration timestamp

  lastPriceUsd?: string; // Last price when tracking started
};

/**
 * Service that manages live price tracking and push notifications for tokens
 * Handles subscription lifecycle and batched push notification delivery
 */
export class PushService {
  private pushRegistry: Map<string, PushItem> = new Map();
  private gqlClient: GqlClient["db"];

  private session: http2.ClientHttp2Session | null = null;
  private subscriptions: Map<string, { subscription: { unsubscribe: () => void }; subCount: number }> = new Map();
  private tokenPrice: Map<string, string> = new Map();
  private activityMutex = new Mutex();

  private readonly JWT_REFRESH_INTERVAL = 15 * 60 * 1000; // 15 minutes in ms
  private cachedJWT?: { token: string; timestamp: number };

  /**
   * Creates a new PushService instance
   * @param args.gqlClient - GraphQL client for price subscriptions
   */
  constructor(args: { gqlClient: GqlClient["db"] }) {
    this.gqlClient = args.gqlClient;

    if (!env.APPLE_AUTHKEY) {
      console.warn("Apple Push Service: No auth key found. Not initializing.");
      return;
    }
    this.initializePushes();
  }

  /**
   * Removes stale entries from the push registry based on configured timeout
   */
  private async cleanupRegistry() {
    const now = Date.now();
    const { PUSH_REGISTRY_TIMEOUT_MS } = await config();
    for (const [key, value] of this.pushRegistry.entries()) {
      if (now - value.timestamp > PUSH_REGISTRY_TIMEOUT_MS) {
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
      console.log(`Incrementing subscription count for token: ${tokenMint}`);
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
  async startLiveActivity(
    userId: string,
    input: { tokenMint: string; tokenPriceUsd: string; deviceToken: string; pushToken: string },
  ) {
    const release = await this.activityMutex.acquire();
    const existing = this.pushRegistry.get(userId);
    try {
      if (existing?.tokenMint !== input.tokenMint) {
        if (existing) {
          this.cleanSubscription(existing.tokenMint);
        }
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
      const { PUSH_CLEANUP_INTERVAL_MS, PUSH_SEND_INTERVAL_MS } = await config();
      setInterval(() => this.cleanupRegistry(), PUSH_CLEANUP_INTERVAL_MS);
      setInterval(() => this.sendAllPushes(), PUSH_SEND_INTERVAL_MS);
    })();
  }

  /**
   * Sends push notifications in batches to all registered users
   */
  private async sendAllPushes() {
    const BATCH_SIZE = 50;
    const entries = Array.from(this.pushRegistry.entries());

    console.log(`Pushing to: ${entries.length} users`);
    for (let i = 0; i < entries.length; i += BATCH_SIZE) {
      const batch = entries.slice(i, i + BATCH_SIZE);
      await Promise.all(batch.map(([userId, value]) => this.sendUpdatePush(userId, value)));
    }
  }

  /**
   * Sends a push notification to update price information
   * @param userId - User identifier
   * @param input - Push notification data containing token and price information
   */
  private async sendUpdatePush(userId: string, input: PushItem) {
    const tokenPrice = this.tokenPrice.get(input.tokenMint);
    if (!tokenPrice || tokenPrice === input.lastPriceUsd) {
      return;
    }
    input.lastPriceUsd = tokenPrice;
    this.pushRegistry.set(userId, input);

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

  /**
   * Sends a final push notification when stopping live activity
   * @param input - Push notification data containing token and price information
   */
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

  /**
   * Gets or creates an HTTP/2 session to Apple's push notification service
   * @returns Active HTTP/2 client session
   */
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

  /**
   * Gets a cached JWT token or generates a new one if expired
   * @returns Valid JWT token for APNS authentication
   */
  private async getJWTToken() {
    const cachedJWT = this.cachedJWT;
    if (cachedJWT && Date.now() - cachedJWT.timestamp < this.JWT_REFRESH_INTERVAL) {
      return cachedJWT.token;
    }

    const jwt = this.generateJWT();

    if (jwt) this.cachedJWT = { token: jwt, timestamp: Date.now() };
    return jwt;
  }

  /**
   * Generates a new JWT token for APNS authentication
   * @returns Newly generated JWT token
   */
  private generateJWT() {
    try {
      const privateKey = env.APPLE_AUTHKEY;
      if (!privateKey) {
        throw new Error("Apple Push Service: No auth key found. Not generating JWT.");
      }
      const secondsSinceEpoch = Math.round(Date.now() / 1000);
      const payload = {
        iss: env.APPLE_PUSH_TEAM_ID,
        iat: secondsSinceEpoch,
      };
      return jwt.sign(payload, privateKey, { algorithm: "ES256", keyid: env.APPLE_PUSH_KEY_ID });
    } catch {
      return undefined;
    }
  }

  /**
   * Publishes a push notification to Apple's Push Notification Service (APNS)
   * @param pushToken - Device-specific push token
   * @param json - Payload to send in the push notification
   */
  private async publishToApns(pushToken: string, json: object) {
    const jwt = await this.getJWTToken();
    if (!jwt) {
      console.error("Push Service: Failed to generate JWT token. Not pushing to APNS");
      return;
    }

    try {
      const buffer = Buffer.from(JSON.stringify(json));
      const session = this.getSession();

      const req = session.request({
        ":method": "POST",
        ":path": "/3/device/" + pushToken,
        authorization: "bearer " + jwt,
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
