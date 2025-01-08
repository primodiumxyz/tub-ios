export class PushService {
  constructor() {}

  async startLiveActivity(
    userId: string,
    input: { tokenMint: string; tokenAmount: string; tokenPriceUsd: string; pushToken: string },
  ) {
    return {
      userId,
      input,
    };
  }

  async stopLiveActivity(userId: string) {
    return {
      userId,
    };
  }

  private async sendPush(
    userId: string,
    input: { tokenMint: string; tokenAmount: string; tokenPriceUsd: string; pushToken: string },
  ) {
    return {
      userId,
      input,
    };
  }
}
