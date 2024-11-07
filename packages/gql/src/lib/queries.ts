import { graphql } from "./init";



export const GetAllMockTokensQuery = graphql(`
  query GetAllTokens {
    token(where: { mint: { _is_null: true } }) {
      id
      name
      symbol
      updated_at
      supply
      uri
    }
  }
`);

export const GetTokenDataQuery = graphql(`
  query GetTokenData($tokenId: uuid!) {
    token(where: { id: { _eq: $tokenId } }) {
      id
      mint
      name
      symbol
      description
      supply
      decimals
      updated_at
      supply
      uri
    }
  }
`);

export const GetTokensByMintsQuery = graphql(`
  query GetTokensByMints($mints: [String!]!) {
    token(where: { mint: { _in: $mints } }) {
      id
      mint
    }
  }
`);

export const GetWalletTokenBalanceQuery = graphql(`
  query GetWalletTokenBalance($wallet: String!, $token: uuid!, $start: timestamptz = "now()") {
    balance: wallet_token_balance_ignore_interval(
      args: { wallet: $wallet, interval: "0", start: $start, token: $token }
    ) {
      value: balance
    }
  }
`);

export const GetWalletTokenBalanceIgnoreIntervalQuery = graphql(`
  query GetWalletTokenBalanceIgnoreInterval(
    $wallet: String!
    $start: timestamptz = "now()"
    $interval: interval!
    $token: uuid!
  ) {
    balance: wallet_token_balance_ignore_interval(
        args: { wallet: $wallet, interval: $interval, start: $start, token: $token }
    ) {
      value: balance
    }
  }
`);

export const GetWalletBalanceQuery = graphql(`
  query GetWalletBalance($wallet: String!, $start: timestamptz = "now()") {
    balance: wallet_balance_ignore_interval(args: { wallet: $wallet, interval: "0", start: $start }) {
      value: balance
    }
  }
`);

export const GetWalletBalanceIgnoreIntervalQuery = graphql(`
  query GetWalletBalanceIgnoreInterval($wallet: String!, $start: timestamptz = "now()", $interval: interval!) {
    balance: wallet_balance_ignore_interval(args: { wallet: $wallet, interval: $interval, start: $start }) {
      value: balance
    }
  }
`);

export const GetTokenPriceHistoryIntervalQuery = graphql(`
  query GetTokenPriceHistoryInterval($token: uuid, $start: timestamptz = "now()", $interval: interval!) {
    token_price_history_offset(
      args: { offset: $interval }
      where: { created_at_offset: { _gte: $start }, token: { _eq: $token } }
      order_by: { created_at: desc }
    ) {
      created_at
      price
    }
  }
`);

export const GetTokenPriceHistoryIgnoreIntervalQuery = graphql(`
  query GetTokenPriceHistoryIgnoreInterval($token: uuid, $start: timestamptz = "now()", $interval: interval!) {
    token_price_history_offset(
      args: { offset: $interval }
      where: { created_at_offset: { _lte: $start }, token: { _eq: $token } }
      order_by: { created_at: desc }
    ) {
      created_at
      price
    }
  }
`);

export const GetLatestTokenPriceQuery = graphql(`
  query GetLatestTokenPrice($tokenId: uuid!) {
    token_price_history(where: { token: { _eq: $tokenId } }, order_by: { created_at: desc }, limit: 1) {
      created_at
      id
      price
      token
    }
  }
`);

export const GetWalletTransactionsQuery = graphql(`
  query GetWalletTransactions($wallet: String!) {
    token_transaction(
      order_by: { wallet_transaction_data: { created_at: desc } }
      where: { wallet_transaction_data: { wallet: { _eq: $wallet } } }
    ) {
      wallet_transaction
      amount
      id
      token
      token_data {
        id
        name
        supply
        symbol
        uri
      }
      wallet_transaction_data {
        created_at
      }
      token_price {
        price
        created_at
      }
    }
  }
`);

export const GetTokenPriceHistorySinceQuery = graphql(`
  query GetTokenPriceHistorySince($tokenId: uuid!, $since: timestamptz!) {
    token_price_history(
      where: { token: { _eq: $tokenId }, created_at: { _gte: $since } }
      order_by: { created_at: asc }
    ) {
      created_at
      id
      price
      token
    }
  }
`);

export const GetFilteredTokensIntervalQuery = graphql(`
  query GetFilteredTokensInterval(
    $interval: interval!
    $minTrades: bigint = 0
    $minVolume: numeric = 0
    $mintBurnt: Boolean = false
    $freezeBurnt: Boolean = false
  ) {
    formatted_tokens_interval(
      args: { interval: $interval }
      where: {
        is_pump_token: { _eq: true }
        trades: { _gte: $minTrades }
        volume: { _gte: $minVolume }
        _and: [
          { _or: [{ _not: { mint_burnt: { _eq: $mintBurnt } } }, { mint_burnt: { _eq: true } }] }
          { _or: [{ _not: { freeze_burnt: { _eq: $freezeBurnt } } }, { freeze_burnt: { _eq: true } }] }
        ]
      }
      order_by: { volume: desc }
    ) {
      token_id
      mint
      name
      symbol
      description
      uri
      supply
      decimals
      mint_burnt
      freeze_burnt
      is_pump_token
      increase_pct
      trades
      volume
      latest_price
      created_at
    }
  }
`);

// Dashboard
export const GetSwapsInPeriodCountQuery = graphql(`
  query GetSwapsInPeriod($from: timestamptz!, $to: timestamptz!) {
    swaps_total: token_price_history_aggregate(where: { created_at: { _gte: $from, _lte: $to } }) {
      aggregate {
        count
      }
    }
    swaps_hourly: hourly_swaps(where: { hour: { _gte: $from, _lte: $to } }) {
      hour
      count
    }
  }
`);

export const GetNewTokensInPeriodCountQuery = graphql(`
  query GetNewTokensInPeriod($from: timestamptz!, $to: timestamptz!) {
    new_tokens_total: token_aggregate(where: { created_at: { _gte: $from, _lte: $to } }) {
      aggregate {
        count
      }
    }
    new_tokens_hourly: hourly_new_tokens(where: { hour: { _gte: $from, _lte: $to } }) {
      hour
      count
    }
  }
`);

export const GetVolumeIntervalsWithinPeriodQuery = graphql(`
  query GetVolumeIntervalsWithinPeriod($from: timestamptz!, $to: timestamptz!, $interval: interval!) {
    volume_intervals_within_period(args: { start: $from, end: $to, interval: $interval }) {
      interval_start
      total_volume
      token_count
    }
  }
`);

export const GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery = graphql(`
  query GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery(
    $from: timestamptz!
    $to: timestamptz!
    $interval: interval!
    $afterIntervals: String!
    $minTrades: bigint = 0
    $minVolume: numeric = 0
    $mintBurnt: Boolean = false
    $freezeBurnt: Boolean = false
  ) {
    formatted_tokens_with_performance_intervals_within_period(
      args: { start: $from, end: $to, interval: $interval, after_intervals: $afterIntervals }
      where: {
        trades: { _gte: $minTrades }
        volume: { _gte: $minVolume }
        _and: [
          { _or: [{ _not: { mint_burnt: { _eq: $mintBurnt } } }, { mint_burnt: { _eq: true } }] }
          { _or: [{ _not: { freeze_burnt: { _eq: $freezeBurnt } } }, { freeze_burnt: { _eq: true } }] }
        ]
      }
      order_by: { interval_start: asc }
    ) {
      token_id
      mint
      name
      symbol
      description
      uri
      supply
      decimals
      mint_burnt
      freeze_burnt
      is_pump_token
      increase_pct
      trades
      volume
      latest_price
      created_at
      increase_pct_after
      trades_after
      volume_after
      interval_start
    }
  }
`);
