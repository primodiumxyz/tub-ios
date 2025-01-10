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
export const GetTopTokensByVolumeQuery = graphql(`
  query GetTopTokensByVolume(
    $interval: interval = "30m"
    $recentInterval: interval = "20s"
    $minRecentTrades: numeric = 0
    $minRecentVolume: numeric = 0
  ) {
    token_stats_interval_comp(
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
