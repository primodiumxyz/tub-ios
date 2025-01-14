import { graphql } from "./init";

// Dashboard
export const GetTopTokensByVolumeSubscription = graphql(`
  subscription SubTopTokensByVolume($interval: interval = "30m", $recentInterval: interval = "20s") {
    token_stats_interval_cache(
      args: { interval: $interval, recent_interval: $recentInterval }
      where: { token_metadata_is_pump_token: { _eq: true } }
      order_by: { total_volume_usd: desc }
      limit: 50
    ) {
      token_mint
      total_volume_usd
      total_trades
      price_change_pct
      latest_price_usd
      token_metadata_name
      token_metadata_image_uri
      token_metadata_symbol
      token_metadata_supply
    }
  }
`);

export const GetTokenPricesSinceSubscription = graphql(`
  subscription SubTokenPricesSince($token: String!, $since: timestamptz = "now()") {
    api_trade_history(
      where: { token_mint: { _eq: $token }, created_at: { _gte: $since } }
      order_by: { created_at: asc }
    ) {
      token_price_usd
      created_at
    }
  }
`);

export const GetTokenCandlesSinceSubscription = graphql(`
  subscription SubTokenCandlesSince($token: String!, $since: timestamptz = "now()") {
    token_candles_history_1min(args: { token_mint: $token, start: $since }) {
      bucket
      open_price_usd
      close_price_usd
      high_price_usd
      low_price_usd
    }
  }
`);
