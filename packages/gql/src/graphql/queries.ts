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

// Benchmarks
export const GetAllTokensQuery = graphql(`
  query GetAllTokens {
    api_token_rolling_stats_30min {
      mint
    }
  }
`);

export const GetTopTokensByVolumeQuery_old = graphql(`
  query GetTopTokensByVolumeCached(
    $interval: interval = "30m"
    $recentInterval: interval = "20s"
    $minRecentTrades: numeric = 0
    $minRecentVolume: numeric = 0
  ) {
    token_stats_interval_cache(
      args: { interval: $interval, recent_interval: $recentInterval }
      where: {
        token_metadata_is_pump_token: { _eq: true }
        recent_trades: { _gte: $minRecentTrades }
        recent_volume_usd: { _gte: $minRecentVolume }
      }
      order_by: { total_volume_usd: desc }
      limit: 50
    ) {
      token_mint
    }
  }
`);

export const GetBulkTokenMetadataQuery_old = graphql(`
  query GetBulkTokenMetadata($tokens: jsonb!) {
    token_metadata_formatted(args: { tokens: $tokens }) {
      mint
      name
      symbol
      image_uri
      supply
      decimals
      description
      external_url
      is_pump_token
    }
  }
`);

export const GetBulkTokenLiveDataQuery_old = graphql(`
  query GetBulkTokenLiveData($tokens: [String!]!) {
    token_stats_interval_cache(
      where: { token_mint: { _in: $tokens } }
      args: { interval: "30m", recent_interval: "1m" }
    ) {
      token_mint
      latest_price_usd
      total_volume_usd
      total_trades
      price_change_pct
      recent_volume_usd
      recent_trades
      recent_price_change_pct
      token_metadata_supply
    }
  }
`);

export const GetTokenLiveDataQuery_old = graphql(`
  query GetTokenLiveData($token: String!) {
    token_stats_interval_cache(
      where: { token_mint: { _eq: $token } }
      args: { interval: "30m", recent_interval: "1m" }
    ) {
      token_mint
      latest_price_usd
      total_volume_usd
      total_trades
      price_change_pct
      recent_volume_usd
      recent_trades
      recent_price_change_pct
      token_metadata_supply
    }
  }
`);

/* ----------------------------------- NEW ---------------------------------- */

export const GetTopTokensByVolumeQuery = graphql(`
  query GetTopTokensByVolumeQuery_new($minRecentTrades: numeric = 0, $minRecentVolume: numeric = 0) {
    api_token_rolling_stats_30min(
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

export const GetTokenMetadataQuery = graphql(`
  query GetTokenMetadataQuery_new($token: String!) {
    api_token_rolling_stats_30min(where: { mint: { _eq: $token } }) {
      mint
      name
      symbol
      image_uri
      supply
      decimals
      description
      external_url
      is_pump_token
    }
  }
`);

export const GetBulkTokenMetadataQuery = graphql(`
  query GetBulkTokenMetadataQuery_new($tokens: [String!]!) {
    api_token_rolling_stats_30min(where: { mint: { _in: $tokens } }) {
      mint
      name
      symbol
      image_uri
      supply
      decimals
      description
      external_url
      is_pump_token
    }
  }
`);

export const GetTokenLiveDataQuery = graphql(`
  query GetTokenLiveDataQuery_new($token: String!) {
    api_token_rolling_stats_30min(where: { mint: { _eq: $token } }) {
      mint
      latest_price_usd
      volume_usd_30m
      trades_30m
      price_change_pct_30m
      volume_usd_1m
      trades_1m
      price_change_pct_1m
      supply
    }
  }
`);

export const GetBulkTokenLiveDataQuery = graphql(`
  query GetBulkTokenLiveDataQuery_new($tokens: [String!]!) {
    api_token_rolling_stats_30min(where: { mint: { _in: $tokens } }) {
      mint
      latest_price_usd
      volume_usd_30m
      trades_30m
      price_change_pct_30m
      volume_usd_1m
      trades_1m
      price_change_pct_1m
      supply
    }
  }
`);
