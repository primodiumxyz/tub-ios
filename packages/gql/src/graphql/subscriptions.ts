import { graphql } from "./init";

// Dashboard
export const GetTopTokensByVolumeSubscription = graphql(`
  subscription SubTopTokensByVolume {
    token_rolling_stats_30min(where: { is_pump_token: { _eq: true } }, order_by: { volume_usd_30m: desc }, limit: 50) {
      mint
      volume_usd_30m
      trades_30m
      price_change_pct_30m
      latest_price_usd
      name
      image_uri
      symbol
      supply
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

export const GetRecentTokenPriceSubscription = graphql(`
  subscription SubRecentTokenPrice($token: String!) {
    api_trade_history(where: { token_mint: { _eq: $token } }, order_by: { created_at: desc }, limit: 1) {
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

export const GetTradesSubscription = graphql(`
  subscription SubTrades($limit: Int = 1000) {
    transactions(order_by: { created_at: desc }, limit: $limit) {
      id
      created_at
      user_wallet
      token_mint
      token_amount
      token_price_usd
      token_value_usd
      success
      error_details
    }
  }
`);

export const GetTradesByUserWalletOrTokenMintSubscription = graphql(`
  subscription SubTradesByUserWalletOrTokenMint($userWalletOrTokenMint: String!, $limit: Int = 1000) {
    transactions(
      where: {
        _or: [{ user_wallet: { _eq: $userWalletOrTokenMint } }, { token_mint: { _eq: $userWalletOrTokenMint } }]
      }
      order_by: { created_at: desc }
      limit: $limit
    ) {
      id
      created_at
      user_wallet
      token_mint
      token_amount
      token_price_usd
      token_value_usd
      success
      error_details
    }
  }
`);
