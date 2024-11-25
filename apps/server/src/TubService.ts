import { EventEmitter } from "events";
import { PrivyClient, WalletWithMetadata } from "@privy-io/server-auth";
import { GqlClient } from "@tub/gql";
import { config } from "dotenv";

config({ path: "../../.env" });

const SOL_USD_UPDATE_INTERVAL = 5 * 1000; // 10 seconds

export class TubService {
  private gql: GqlClient["db"];
  private privy: PrivyClient;
  private solUsdPrice: number | undefined;
  private priceEmitter = new EventEmitter();

  constructor(gqlClient: GqlClient["db"], privy: PrivyClient) {
    this.gql = gqlClient;
    this.privy = privy;

    // Update the SOL/USD price every 10 seconds
    const interval = setInterval(() => {
      this.updateSolUsdPrice();
    }, SOL_USD_UPDATE_INTERVAL);
    this.updateSolUsdPrice();

    interval.unref(); // allow Node.js to exit if only this interval is still running
  }

  getStatus(): { status: number } {
    return { status: 200 };
  }

  async sellToken(jwtToken: string, tokenId: string, amount: bigint, tokenPrice: number) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.SellTokenMutation({
      wallet,
      token: tokenId,
      amount: amount.toString(),
      token_price: tokenPrice.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async buyToken(jwtToken: string, tokenId: string, amount: bigint, tokenPrice: number) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.BuyTokenMutation({
      wallet,
      token: tokenId,
      amount: amount.toString(),
      token_price: tokenPrice.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }
    return result.data;
  }

  async airdropNativeToUser(jwtToken: string, amount: bigint) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.AirdropNativeToWalletMutation({
      wallet,
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
      metadata?: string;
      errorDetails?: string;
      source?: string;
      buildVersion?: string;
    },
    token: string,
  ) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const result = await this.gql.AddClientEventMutation({
      user_agent: event.userAgent,
      event_name: event.eventName,
      metadata: event.metadata,
      user_wallet: wallet,
      error_details: event.errorDetails,
      source: event.source,
      build: event.buildVersion,
    });

    const id = result.data?.insert_analytics_client_event_one?.id;

    if (!id) {
      throw new Error("Failed to record client event. Missing ID.");
    }

    if (result.error) {
      throw new Error(result.error.message);
    }

    return id;
  }

  async getSolUsdPrice(): Promise<number | undefined> {
    if (!this.solUsdPrice) await this.updateSolUsdPrice();
    return this.solUsdPrice;
  }

  subscribeSolPrice(callback: (price: number) => void): () => void {
    this.priceEmitter.on("price", callback);
    // Send current price immediately if available
    if (this.solUsdPrice !== undefined) callback(this.solUsdPrice);

    // Return cleanup function
    return () => {
      this.priceEmitter.off("price", callback);
    };
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

    const solanaWallet = user.linkedAccounts.find(
      (account) => account.type === "wallet" && account.chainType === "solana",
    ) as WalletWithMetadata | undefined;
    return solanaWallet?.address;
  }

  private async updateSolUsdPrice(): Promise<void> {
    const res = await fetch(`${process.env.JUPITER_API_ENDPOINT}/price?ids=SOL`);
    const data = (await res.json()) as { data: { [id: string]: { price: number } } };

    this.solUsdPrice = data.data["SOL"]?.price;
    if (this.solUsdPrice !== undefined) this.priceEmitter.emit("price", this.solUsdPrice);

    console.log(`SOL/USD price updated: ${this.solUsdPrice?.toLocaleString("en-US", { maximumFractionDigits: 2 })}`);
  }
}
