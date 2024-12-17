export class MockPrivyClient {
  private testWalletAddress: string;

  constructor(testWalletAddress: string) {
    this.testWalletAddress = testWalletAddress;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async verifyAuthToken(_: string) {
    return { userId: "test_user_id" };
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async getUserById(_: string) {
    return {
      linkedAccounts: [
        {
          type: "wallet",
          chainType: "solana",
          address: this.testWalletAddress,
        },
      ],
    };
  }
}
