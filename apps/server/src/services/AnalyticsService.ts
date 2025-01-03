import { AppDwellTimeEvent, LoadingTimeEvent, TokenDwellTimeEvent, TokenPurchaseOrSaleEvent } from "../types";
import { GqlClient } from "@tub/gql";

export class AnalyticsService {
  constructor(private gql: GqlClient["db"]) {}

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

  async recordLoadingTime(event: LoadingTimeEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddLoadingTimeMutation({
      identifier: event.identifier,
      time_elapsed_ms: event.timeElapsedMs.toString(),
      attempt_number: event.attemptNumber.toString(),
      total_time_ms: event.totalTimeMs.toString(),
      average_time_ms: event.averageTimeMs.toString(),
      user_agent: event.userAgent,
      user_wallet: userWallet,
      source: event.source,
      error_details: event.errorDetails,
      build: event.buildVersion,
    });

    const id = result.data?.insert_loading_time_one?.id;

    if (!id) {
      throw new Error("Failed to record loading time. Missing ID.");
    }

    return id;
  }

  async recordAppDwellTime(event: AppDwellTimeEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddAppDwellTimeMutation({
      dwell_time_ms: event.dwellTimeMs.toString(),
      user_agent: event.userAgent,
      user_wallet: userWallet,
      source: event.source,
      error_details: event.errorDetails,
      build: event.buildVersion,
    });

    const id = result.data?.insert_app_dwell_time_one?.id;

    if (!id) {
      throw new Error("Failed to record app dwell time. Missing ID.");
    }

    return id;
  }

  async recordTokenDwellTime(event: TokenDwellTimeEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddTokenDwellTimeMutation({
      token_mint: event.tokenMint,
      dwell_time_ms: event.dwellTimeMs.toString(),
      user_agent: event.userAgent,
      user_wallet: userWallet,
      source: event.source,
      error_details: event.errorDetails,
      build: event.buildVersion,
    });

    const id = result.data?.insert_token_dwell_time_one?.id;

    if (!id) {
      throw new Error("Failed to record token dwell time. Missing ID.");
    }

    return id;
  }
}
