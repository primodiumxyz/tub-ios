import { PrivyClient } from "@privy-io/server-auth";
import { GqlClient } from "@tub/gql";
import { config } from "dotenv";

config({ path: "../../.env" });

export class TubService {
  private privy: PrivyClient;
  private gql: GqlClient["db"];

  constructor(gqlClient: GqlClient["db"], privy: PrivyClient) {
    this.gql = gqlClient;
    this.privy = privy;
  }

  private verifyJWT = async (token: string) => {
    try {
      const verifiedClaims = await this.privy.verifyAuthToken(token);
      return verifiedClaims.userId;
    } catch (e: any) {
      throw new Error(`Invalid JWT: ${e.message}`);
    }
  };

  private async getUserWallet(userId: string) {
    const user = await this.privy.getUserById(userId);
    return user.wallet?.address;
  }

  getStatus(): { status: number } {
    return { status: 200 };
  }

  async sellToken(token: string, tokenId: string, amount: bigint, overridePrice?: bigint) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const result = await this.gql.SellTokenMutation({
      wallet: wallet,
      token: tokenId,
      amount: amount.toString(),
      override_token_price: overridePrice?.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async buyToken(token: string, tokenId: string, amount: bigint, overridePrice?: bigint) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const result = await this.gql.BuyTokenMutation({
      wallet: wallet,
      token: tokenId,
      amount: amount.toString(),
      override_token_price: overridePrice?.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async registerNewToken(name: string, symbol: string, supply: bigint = 100n, uri?: string) {
    const result = await this.gql.RegisterNewTokenMutation({
      name: name,
      symbol: symbol,
      supply: supply.toString(),
      uri: uri,
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async airdropNativeToUser(token: string, amount: bigint) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const result = await this.gql.AirdropNativeToWalletMutation({
      wallet: wallet,
      amount: amount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async recordClientEvent(
    event: {
      userAgent: string;
      eventName: string;
      metadata?: Record<string, unknown>;
      errorDetails?: string;
      source?: string;
      build_version?: string;
    },
    token: string,
  ) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    await this.gql.AddClientEventMutation({
      user_agent: event.userAgent,
      event_name: event.eventName,
      metadata: event.metadata,
      user_wallet: wallet,
      error_details: event.errorDetails,
      source: event.source,
      build: event.build_version,
    });
  }
}
