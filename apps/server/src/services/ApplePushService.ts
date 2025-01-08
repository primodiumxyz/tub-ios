import { GqlClient } from "@tub/gql";

type PushItem = {
  tokenMint: string;
  initialPriceUsd: string;
  pushToken: string;
  timestamp: number;
};

export class PushService {
  private pushRegistry: Map<string, PushItem> = new Map();
  private REGISTRY_TIMEOUT = 1 * 60 * 60 * 1000; // 6 hours
  private gqlClient: GqlClient["db"];

  private subscriptions: Map<string, { subscription: { unsubscribe: () => void }; subCount: number }> = new Map();
  private tokenPrice: Map<string, string> = new Map();

  constructor(args: { gqlClient: GqlClient["db"] }) {
    this.initializePushes();
    this.gqlClient = args.gqlClient;
  }

  private async cleanupRegistry() {
    const now = Date.now();
    for (const [key, value] of this.pushRegistry.entries()) {
      if (now - value.timestamp > this.REGISTRY_TIMEOUT) {
        this.pushRegistry.delete(key);
        this.cleanSubscription(value.tokenMint);
      }
    }
  }

  /* ------------------------------ Subscriptions ----------------------------- */

  private beginTokenSubscription(tokenMint: string) {
    console.log("Begin token subscription", tokenMint);
    if (this.subscriptions.has(tokenMint)) {
      console.log("Already subscribed");
      this.subscriptions.get(tokenMint)!.subCount++;
      return;
    }

    const subscription = this.gqlClient
      .GetRecentTokenPriceSubscription({
        token: tokenMint,
      })
      .subscribe((data) => {
        console.log("Token price changed", data);
        if (!data?.data?.api_trade_history[0]) return;
        console.log("token price update", tokenMint, data.data.api_trade_history[0].token_price_usd);
        this.tokenPrice.set(tokenMint, data.data.api_trade_history[0].token_price_usd);
      });
    console.log("Subscribed to token", tokenMint);

    this.subscriptions.set(tokenMint, { subscription, subCount: 1 });
  }

  private async cleanSubscription(tokenMint: string) {
    console.log("Clean subscription", tokenMint);
    if (this.subscriptions.has(tokenMint)) {
      this.subscriptions.get(tokenMint)!.subCount--;
      if (this.subscriptions.get(tokenMint)!.subCount === 0) {
        console.log("Unsubscribing from token", tokenMint);
        this.subscriptions.get(tokenMint)!.subscription.unsubscribe();
        this.subscriptions.delete(tokenMint);
        this.tokenPrice.delete(tokenMint);
      }
    }
  }

  /* --------------------------------- Live activity --------------------------------- */

  async startLiveActivity(userId: string, input: { tokenMint: string; tokenPriceUsd: string; pushToken: string }) {
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
  }

  async stopLiveActivity(userId: string) {
    console.log("Stop live activity", userId);
    if (!this.pushRegistry.has(userId)) {
      return;
    }

    const tokenMint = this.pushRegistry.get(userId)!.tokenMint;
    this.pushRegistry.delete(userId);
    this.cleanSubscription(tokenMint);
  }

  /* --------------------------------- Pushes --------------------------------- */

  private initializePushes(): void {
    (async () => {
      setInterval(() => this.cleanupRegistry(), 1 * 60 * 1000);
      setInterval(() => this.sendAllPushes(), 5 * 1000);
    })();
  }

  private async sendAllPushes() {
    for (const [key, value] of this.pushRegistry.entries()) {
      await this.sendPush(key, value);
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
