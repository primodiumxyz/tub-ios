import { GqlClient } from "@tub/gql";
import { config } from "../utils/config";

/**
 * Service for managing periodic background tasks
 * Handles scheduled operations like token statistics updates
 */
export class CronService {
  /**
   * Creates a new CronService instance
   * @param gql - GraphQL client for database operations
   */
  constructor(private gql: GqlClient["db"]) {}

  /**
   * Updates rolling statistics for token refresh operations
   * @throws Error if statistics update fails
   */
  async refreshTokenRollingStats30Min(): Promise<void> {
    const result = await this.gql.RefreshTokenRollingStats30MinMutation();
    if (result.error) throw new Error(result.error.message);
    if (!result.data?.api_refresh_token_rolling_stats_30min?.success)
      throw new Error("Failed to refresh token rolling stats 30min");
  }

  /**
   * Starts all periodic background tasks
   * Currently manages token rolling statistics updates
   */
  async startPeriodicTasks(): Promise<void> {
    const { REFRESH_TOKEN_ROLLING_STATS_30MIN_INTERVAL_SECONDS } = await config();

    setInterval(async () => {
      try {
        await this.refreshTokenRollingStats30Min();
      } catch (error) {
        console.error("Failed to refresh token rolling stats 30min", error);
      }
    }, REFRESH_TOKEN_ROLLING_STATS_30MIN_INTERVAL_SECONDS * 1000);
  }
}
