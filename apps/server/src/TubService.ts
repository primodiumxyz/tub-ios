import { PrivyClient } from "@privy-io/server-auth";
import { GqlClient } from "@tub/gql";
import { config } from "dotenv";

config({ path: "../../.env" });

export class TubService {
  private gql: GqlClient["db"];

  constructor(gqlClient: GqlClient["db"], privy: PrivyClient) {
    this.gql = gqlClient;
    /* tslint:disable:no-unused-variable */
    const _privy = privy;
  }

  getStatus(): { status: number } {
    return { status: 200 };
  }

  async sellToken(userId: string, tokenId: string, amount: bigint, overridePrice?: bigint) {
    const result = await this.gql.SellTokenMutation({
      wallet: userId,
      token: tokenId,
      amount: amount.toString(),
      override_token_price: overridePrice?.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async buyToken(userId: string, tokenId: string, amount: bigint, overridePrice?: bigint) {
    const result = await this.gql.BuyTokenMutation({
      wallet: userId,
      token: tokenId,
      amount: amount.toString(),
      override_token_price: overridePrice?.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async airdropNativeToUser(userId: string, amount: bigint) {
    const result = await this.gql.AirdropNativeToWalletMutation({
      wallet: userId,
      amount: amount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }
}
