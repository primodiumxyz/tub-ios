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
    token_rolling_stats_30min {
      mint
    }
  }
`);

export const GetTopTokensByVolumeQuery = graphql(`
  query GetTopTokensByVolumeQuery($minRecentTrades: numeric = 0, $minRecentVolume: numeric = 0) {
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

export const GetTokenMetadataQuery = graphql(`
  query GetTokenMetadataQuery($token: String!) {
    token_rolling_stats_30min(where: { mint: { _eq: $token } }) {
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
  query GetBulkTokenMetadataQuery($tokens: [String!]!) {
    token_rolling_stats_30min(where: { mint: { _in: $tokens } }) {
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
  query GetTokenLiveDataQuery($token: String!) {
    token_rolling_stats_30min(where: { mint: { _eq: $token } }) {
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
  query GetBulkTokenLiveDataQuery($tokens: [String!]!) {
    token_rolling_stats_30min(where: { mint: { _in: $tokens } }) {
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
