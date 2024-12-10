import { GqlClient } from "@tub/gql";

export interface ClientEvent {
  userAgent: string;
  eventName: string;
  metadata?: string;
  errorDetails?: string;
  source?: string;
  buildVersion?: string;
}

export type TokenPurchaseOrSaleEvent = Omit<ClientEvent, "eventName" | "metadata"> & {
  tokenMint: string;
  tokenAmount: string;
  tokenPriceUsd: string;
};

export class AnalyticsService {
  constructor(private gql: GqlClient["db"]) {}

  async recordClientEvent(event: ClientEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddClientEventMutation({
      user_agent: event.userAgent,
      event_name: event.eventName,
      metadata: event.metadata,
      user_wallet: userWallet,
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

  async recordTokenPurchase(event: TokenPurchaseOrSaleEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddTokenPurchaseMutation({
      token_mint: event.tokenMint,
      token_amount: event.tokenAmount,
      token_price_usd: event.tokenPriceUsd,
      user_agent: event.userAgent,
      user_wallet: userWallet,
      error_details: event.errorDetails,
      source: event.source,
      build: event.buildVersion,
    });

    const id = result.data?.insert_token_purchase_one?.id;

    if (!id) {
      throw new Error("Failed to record token purchase. Missing ID.");
    }

    return id;
  }

  async recordTokenSale(event: TokenPurchaseOrSaleEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddTokenSaleMutation({
      token_mint: event.tokenMint,
      token_amount: event.tokenAmount,
      token_price_usd: event.tokenPriceUsd,
      user_agent: event.userAgent,
      user_wallet: userWallet,
      error_details: event.errorDetails,
      source: event.source,
      build: event.buildVersion,
    });

    const id = result.data?.insert_token_sale_one?.id;

    if (!id) {
      throw new Error("Failed to record token sale. Missing ID.");
    }

    return id;
  }
}
