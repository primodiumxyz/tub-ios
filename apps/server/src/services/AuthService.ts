import { PrivyClient } from "@privy-io/server-auth";
import { PublicKey } from "@solana/web3.js";

export type UserContext = {
  userId: string;
  walletPublicKey: PublicKey;
};

export class AuthService {
  constructor(private privy: PrivyClient) {}

  /**
   * Verifies a JWT token and returns the associated user context
   * @param token - JWT token to verify
   * @returns The verified user context including wallet
   * @throws Error if JWT is invalid or user has no wallet
   */
  async getUserContext(token: string): Promise<UserContext> {
    try {
      const verifiedClaims = await this.privy.verifyAuthToken(token);
      const userId = verifiedClaims.userId;
      if (!userId) {
        throw new Error("User is not registered with Privy");
      }

      const user = await this.privy.getUser(userId);
      const solanaWallet = user.linkedAccounts.find(
        (account) => account.type === "wallet" && account.walletClientType === "solana",
      );

      if (!solanaWallet?.address) {
        throw new Error("User does not have a wallet registered with Privy");
      }

      return {
        userId,
        walletPublicKey: new PublicKey(solanaWallet.address),
      };
    } catch (e: unknown) {
      throw new Error(`Invalid JWT or user context: ${e instanceof Error ? e.message : "Unknown error"}`);
    }
  }
}
