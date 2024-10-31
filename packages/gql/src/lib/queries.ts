import { graphql } from "./init";

export const GetAllAccountsQuery = graphql(`
  query GetAllAccounts {
    account {
      id
      username
      created_at
    }
  }
`);

export const GetAccountDataQuery = graphql(`
  query GetAccountData($accountId: uuid!) {
    account(where: { id: { _eq: $accountId } }) {
      username
      id
      created_at
    }
  }
`);

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
      name
      symbol
      mint
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

export const GetAccountTokenBalanceQuery = graphql(`
  query GetAccountTokenBalance($account: uuid!, $token: uuid!, $start: timestamptz = "now()") {
    balance: account_token_balance_ignore_interval(
      args: { account: $account, interval: "0", start: $start, token: $token }
    ) {
      value: balance
    }
  }
`);

export const GetAccountTokenBalanceIgnoreIntervalQuery = graphql(`
  query GetAccountTokenBalanceIgnoreInterval(
    $account: uuid!
    $start: timestamptz = "now()"
    $interval: interval!
    $token: uuid!
  ) {
    balance: account_token_balance_ignore_interval(
      args: { account: $account, interval: $interval, start: $start, token: $token }
    ) {
      value: balance
    }
  }
`);

export const GetAccountBalanceQuery = graphql(`
  query GetAccountBalance($account: uuid!, $start: timestamptz = "now()") {
    balance: account_balance_ignore_interval(args: { account: $account, interval: "0", start: $start }) {
      value: balance
    }
  }
`);

export const GetAccountBalanceIgnoreIntervalQuery = graphql(`
  query GetAccountBalanceIgnoreInterval($account: uuid!, $start: timestamptz = "now()", $interval: interval!) {
    balance: account_balance_ignore_interval(args: { account: $account, interval: $interval, start: $start }) {
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

export const GetAccountTransactionsQuery = graphql(`
  query GetAccountTransactions($accountId: uuid!) {
    token_transaction(
      order_by: { account_transaction_data: { created_at: desc } }
      where: { account_transaction_data: { account_data: { id: { _eq: $accountId } } } }
    ) {
      account_transaction
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
      account_transaction_data {
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

export const GetFilteredTokensQuery = graphql(`
  query GetFilteredTokens($since: timestamptz!, $minTrades: bigint!, $minIncreasePct: float8!) {
    get_formatted_tokens_since(
      args: { since: $since }
      where: { trades: { _gte: $minTrades }, increase_pct: { _gte: $minIncreasePct } }
    ) {
      token_id
      mint
      decimals
      name
      symbol
      platform
      latest_price
      increase_pct
      trades
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

export const GetFormattedTokensCountForIntervalsWithinPeriodQuery = graphql(`
  query GetFormattedTokensCountForIntervalsWithinPeriodQuery(
    $from: timestamptz!
    $to: timestamptz!
    $interval: interval!
    $increasePct: float8!
    $minTrades: bigint!
  ) {
    get_formatted_tokens_intervals_within_period_aggregate(
      args: { start: $from, end: $to, interval: $interval, trades: $minTrades, increase_pct: $increasePct }
    ) {
      interval_start
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
    $increasePct: float8!
    $minTrades: bigint!
    $mintFilter: String = "%"
  ) {
    get_formatted_tokens_with_performance_intervals_within_period(
      args: { start: $from, end: $to, interval: $interval, after_intervals: $afterIntervals }
      where: { trades: { _gte: $minTrades }, increase_pct: { _gte: $increasePct }, mint: { _ilike: $mintFilter } }
      order_by: { interval_start: asc }
    ) {
      mint
      increase_pct
      trades
      increase_pct_after
      trades_after
      created_at
      interval_start
    }
  }
`);
