import { graphql } from "./init";

export const GetWalletTransactionsQuery = graphql(`
  query GetWalletTransactions($wallet: String!) {
    transactions(where: { user_wallet: { _eq: $wallet }, success: { _eq: true } }, order_by: { created_at: desc }) {
      id
      created_at
      token_mint
      token_amount
      token_price_usd
      token_value_usd
    }
  }
`);

export const GetLatestTokenPurchaseQuery = graphql(`
  query GetLatestTokenPurchase($wallet: String!, $mint: String!) {
    transactions(
      where: {
        user_wallet: { _eq: $wallet }
        token_mint: { _eq: $mint }
        success: { _eq: true }
        token_amount: { _gt: 0 }
      }
      order_by: { created_at: desc }
      limit: 1
    ) {
      id
      created_at
      token_mint
      token_amount
      token_price_usd
      token_value_usd
    }
  }
`);

export const GetWalletTokenPnlQuery = graphql(`
  query GetWalletTokenPnl($wallet: String!, $token_mint: String!) {
    transactions_value_aggregate(where: { user_wallet: { _eq: $wallet }, token_mint: { _eq: $token_mint } }) {
      total_value_usd
    }
  }
`);

export const GetTopTokensByVolumeQuery = graphql(`
  query GetTopTokensByVolume($minRecentTrades: numeric = 0, $minRecentVolume: numeric = 0) {
    token_rolling_stats_30min(
      where: {
        is_pump_token: { _eq: true }
        trades_1m: { _gte: $minRecentTrades }
        volume_usd_1m: { _gte: $minRecentVolume }
      }
      order_by: { volume_usd_30m: desc }
      limit: 50
    ) {
      mint
    }
  }
`);

export const GetTokenPricesSinceQuery = graphql(`
  query GetTokenPricesSince($token: String!, $since: timestamptz = "now()") {
    api_trade_history(
      where: { token_mint: { _eq: $token }, created_at: { _gte: $since } }
      order_by: { created_at: asc }
    ) {
      token_price_usd
      created_at
    }
  }
`);

export const GetTokenCandlesSinceQuery = graphql(`
  query GetTokenCandlesSince($token: String!, $since: timestamptz = "now()") {
    token_candles_history_1min(args: { token_mint: $token, start: $since }) {
      bucket
      open_price_usd
      close_price_usd
      high_price_usd
      low_price_usd
      volume_usd
      has_trades
    }
  }
`);

export const GetBulkTokenMetadataQuery = graphql(`
  query GetBulkTokenMetadata($tokens: [String!]!) {
    token_rolling_stats_30min(where: { mint: { _in: $tokens } }) {
      mint
      name
      symbol
      description
      image_uri
      external_url
      decimals
    }
  }
`);

export const GetTokenLiveDataQuery = graphql(`
  query GetTokenLiveData($token: String!) {
    token_rolling_stats_30min(where: { mint: { _eq: $token } }) {
      mint
      name
      symbol
      description
      image_uri
      external_url
      decimals
    }
  }
`);

export const GetBulkTokenFullDataQuery = graphql(`
  query GetBulkTokenFullData($tokens: [String!]!) {
    token_rolling_stats_30min(where: { mint: { _in: $tokens } }) {
      # Metadata
      mint
      name
      symbol
      description
      image_uri
      external_url
      decimals
      # Live data
      supply
      latest_price_usd
      volume_usd_30m
      trades_30m
      price_change_pct_30m
      volume_usd_1m
      trades_1m
      price_change_pct_1m
    }
  }
`);

export const GetTokenFullDataQuery = graphql(`
  query GetTokenFullData($token: String!) {
    token_rolling_stats_30min(where: { mint: { _eq: $token } }) {
      # Metadata
      mint
      name
      symbol
      description
      image_uri
      external_url
      decimals
      # Live data
      supply
      latest_price_usd
      volume_usd_30m
      trades_30m
      price_change_pct_30m
      volume_usd_1m
      trades_1m
      price_change_pct_1m
    }
  }
`);
