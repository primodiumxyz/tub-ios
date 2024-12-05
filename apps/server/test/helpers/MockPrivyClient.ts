import { PrivyClient } from "@privy-io/server-auth";

export class MockPrivyClient {
  private testWalletAddress: string;

  constructor(testWalletAddress: string) {
    this.testWalletAddress = testWalletAddress;
  }

  async verifyAuthToken(_token: string) {
    return { userId: "test_user_id" };
  }

  async getUserById(_userId: string) {
    return {
      linkedAccounts: [
        {
          type: "wallet",
          chainType: "solana",
          address: this.testWalletAddress
        }
      ]
    };
  }
} 