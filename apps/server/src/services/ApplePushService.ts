import { GqlClient } from "@tub/gql";
import { Mutex } from "async-mutex";
import { Config } from "./ConfigService";

type PushItem = {
  tokenMint: string;
  initialPriceUsd: string;
  pushToken: string;
  timestamp: number;
};

/**
 * Potential issues in the PushService:
 *
 * Memory Leaks:
 * - The tokenPrice Map isn't cleaned up when subscriptions are removed
 * - No maximum limit on number of subscriptions/registrations
 *
 * Race Conditions:
 * - Multiple concurrent calls to start/stop activities could cause inconsistent state
 * - No locking mechanism for shared state modifications
 *
 * Error Handling:
 * - No error handling for subscription failures
 * - No retry mechanism for failed push notifications
 *
 * Scalability:
 * - Single interval for all cleanup operations could become bottleneck
 * - All state is kept in memory - won't work across multiple instances
 *
 * Edge Cases:
 * - No handling of duplicate push tokens
 * - No validation of input data
 * - No handling of network disconnections/reconnections
 *
 * Testing Gaps:
 * - Need tests for push notification sending logic
 * - Need tests for subscription data handling
 * - Need load testing for concurrent operations
 *
 * Configuration:
 * - Hardcoded timeout values
 * - No configurable limits or thresholds
 *
 * Monitoring:
 * - No metrics for failed operations
 * - No logging of important state changes
 */

export class PushService {
  private config: Config;
  private pushRegistry: Map<string, PushItem> = new Map();
  private gqlClient: GqlClient["db"];

  private subscriptions: Map<string, { subscription: { unsubscribe: () => void }; subCount: number }> = new Map();
  private tokenPrice: Map<string, string> = new Map();
  private activityMutex = new Mutex();

  constructor(args: { gqlClient: GqlClient["db"]; config: Config }) {
    this.config = args.config;
    this.initializePushes();
    this.gqlClient = args.gqlClient;
  }

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
        if (!data?.data?.api_trade_history[0]) return;
      });
    console.log("Subscribed to token", tokenMint);

    this.subscriptions.set(tokenMint, { subscription, subCount: 1 });
  }

  private async cleanSubscription(tokenMint: string) {
    if (this.subscriptions.has(tokenMint)) {
      this.subscriptions.get(tokenMint)!.subCount--;
      if (this.subscriptions.get(tokenMint)!.subCount === 0) {
        this.subscriptions.get(tokenMint)!.subscription.unsubscribe();
        this.subscriptions.delete(tokenMint);
        this.tokenPrice.delete(tokenMint);
      }
    }
  }

  /* --------------------------------- Live activity --------------------------------- */

  async startLiveActivity(userId: string, input: { tokenMint: string; tokenPriceUsd: string; pushToken: string }) {
    const release = await this.activityMutex.acquire();
    try {
      if (this.pushRegistry.has(userId)) {
        return;
      }
      this.pushRegistry.set(userId, {
        tokenMint: input.tokenMint,
        initialPriceUsd: input.tokenPriceUsd,
        pushToken: input.pushToken,
        timestamp: Date.now(),
      });
      this.beginTokenSubscription(input.tokenMint);
    } finally {
      release();
    }
  }

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

  private initializePushes(): void {
    (async () => {
      setInterval(() => this.cleanupRegistry(), this.config.PUSH_CLEANUP_INTERVAL_MS);
      setInterval(() => this.sendAllPushes(), this.config.PUSH_SEND_INTERVAL_MS);
    })();
  }

  private async sendAllPushes() {
    const BATCH_SIZE = 50;
    const entries = Array.from(this.pushRegistry.entries());

    for (let i = 0; i < entries.length; i += BATCH_SIZE) {
      const batch = entries.slice(i, i + BATCH_SIZE);
      await Promise.all(batch.map(([key, value]) => this.sendPush(key, value)));
    }
  }

  private async sendPush(userId: string, input: PushItem) {
    const tokenPrice = this.tokenPrice.get(input.tokenMint);
    if (!tokenPrice) return;
    const payload = {
      tokenPrice,
    };
    console.log("Sending push", userId, input, payload);
  }
}
