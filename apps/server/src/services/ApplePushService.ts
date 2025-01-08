type PushItem = {
  tokenMint: string;
  initialPriceUsd: string;
  pushToken: string;
  timestamp: number;
};

export class PushService {
  private pushRegistry: Map<string, PushItem> = new Map();
  private REGISTRY_TIMEOUT = 1 * 60 * 60 * 1000; // 6 hours

  constructor() {
    this.initializePushes();
  }

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

  private async cleanupRegistry() {
    const now = Date.now();
    for (const [key, value] of this.pushRegistry.entries()) {
      if (now - value.timestamp > this.REGISTRY_TIMEOUT) {
        this.pushRegistry.delete(key);
      }
    }
  }

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
  }

  async stopLiveActivity(userId: string) {
    if (!this.pushRegistry.has(userId)) {
      return;
    }

    this.pushRegistry.delete(userId);
  }

  private async sendPush(userId: string, input: PushItem) {
    console.log("Sending push", userId, input);
  }
}
