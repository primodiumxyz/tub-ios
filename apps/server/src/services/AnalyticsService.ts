import { GqlClient } from "@tub/gql";

import { AppDwellTimeEvent, LoadingTimeEvent, TokenDwellTimeEvent, TokenPurchaseOrSaleEvent } from "@/types";

/**
 * Service for tracking and recording various analytics events Handles token transactions, loading times, and user
 * engagement metrics
 */
export class AnalyticsService {
  /**
   * Creates a new AnalyticsService instance
   *
   * @param gql - GraphQL client for database operations
   */
  constructor(private gql: GqlClient["db"]) {}

  /**
   * Records a token purchase event
   *
   * @param event - Token purchase event details
   * @param userWallet - User's wallet address
   * @returns Promise resolving to event ID
   * @throws Error if recording fails
   */
  async recordTokenPurchase(event: TokenPurchaseOrSaleEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddTokenPurchaseMutation({
      token_mint: event.tokenMint,
      token_amount: event.tokenAmount,
      token_price_usd: event.tokenPriceUsd,
      token_decimals: event.tokenDecimals,
      user_agent: event.userAgent,
      user_wallet: userWallet,
      error_details: event.errorDetails,
      source: event.source,
      build: event.buildVersion,
    });

    if (result.error) throw new Error(result.error.message);

    const id = result.data?.insert_token_purchase_one?.id;
    if (!id) throw new Error("Failed to record token purchase. Missing ID.");

    return id;
  }

  /**
   * Records a token sale event
   *
   * @param event - Token sale event details
   * @param userWallet - User's wallet address
   * @returns Promise resolving to event ID
   * @throws Error if recording fails
   */
  async recordTokenSale(event: TokenPurchaseOrSaleEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddTokenSaleMutation({
      token_mint: event.tokenMint,
      token_amount: event.tokenAmount,
      token_price_usd: event.tokenPriceUsd,
      token_decimals: event.tokenDecimals,
      user_agent: event.userAgent,
      user_wallet: userWallet,
      error_details: event.errorDetails,
      source: event.source,
      build: event.buildVersion,
    });

    if (result.error) throw new Error(result.error.message);

    const id = result.data?.insert_token_sale_one?.id;
    if (!id) throw new Error("Failed to record token sale. Missing ID.");

    return id;
  }

  /**
   * Records application loading time metrics
   *
   * @param event - Loading time event details
   * @param userWallet - User's wallet address
   * @returns Promise resolving to event ID
   * @throws Error if recording fails
   */
  async recordLoadingTime(event: LoadingTimeEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddLoadingTimeMutation({
      identifier: event.identifier,
      time_elapsed_ms: event.timeElapsedMs.toString(),
      attempt_number: event.attemptNumber,
      total_time_ms: event.totalTimeMs.toString(),
      average_time_ms: event.averageTimeMs.toString(),
      user_agent: event.userAgent,
      user_wallet: userWallet,
      source: event.source,
      error_details: event.errorDetails,
      build: event.buildVersion,
    });

    if (result.error) throw new Error(result.error.message);

    const id = result.data?.insert_loading_time_one?.id;
    if (!id) throw new Error("Failed to record loading time. Missing ID.");

    return id;
  }

  /**
   * Records application dwell time metrics
   *
   * @param event - App dwell time event details
   * @param userWallet - User's wallet address
   * @returns Promise resolving to event ID
   * @throws Error if recording fails
   */
  async recordAppDwellTime(event: AppDwellTimeEvent, userWallet: string): Promise<string> {
    const result = await this.gql.AddAppDwellTimeMutation({
      dwell_time_ms: event.dwellTimeMs.toString(),
      user_agent: event.userAgent,
      user_wallet: userWallet,
      source: event.source,
      error_details: event.errorDetails,
      build: event.buildVersion,
    });

    if (result.error) throw new Error(result.error.message);

    const id = result.data?.insert_app_dwell_time_one?.id;
    if (!id) throw new Error("Failed to record app dwell time. Missing ID.");

    return id;
  }

  /**
   * Records token-specific dwell time metrics
   *
   * @param event - Token dwell time event details
   * @param userWallet - User's wallet address
   * @returns Promise resolving to event ID
   * @throws Error if recording fails
   */
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

    if (result.error) throw new Error(result.error.message);

    const id = result.data?.insert_token_dwell_time_one?.id;
    if (!id) throw new Error("Failed to record token dwell time. Missing ID.");

    return id;
  }
}
