import { GqlClient } from "@tub/gql";

export class CronService {
  private static REFRESH_TOKEN_ROLLING_STATS_30MIN_INTERVAL_SECONDS = 5;

  constructor(private gql: GqlClient["db"]) {}

  async refreshTokenRollingStats30Min(): Promise<void> {
    const result = await this.gql.RefreshTokenRollingStats30MinMutation();
    if (result.error) throw new Error(result.error.message);
    if (!result.data?.api_refresh_token_rolling_stats_30min?.success)
      throw new Error("Failed to refresh token rolling stats 30min");
  }

  async startPeriodicTasks(): Promise<void> {
    setInterval(async () => {
      try {
        await this.refreshTokenRollingStats30Min();
      } catch (error) {
        console.error("Failed to refresh token rolling stats 30min", error);
      }
    }, CronService.REFRESH_TOKEN_ROLLING_STATS_30MIN_INTERVAL_SECONDS * 1000);
  }
}
