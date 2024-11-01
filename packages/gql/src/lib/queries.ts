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

// TODO: order by volume once integrated
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
      order_by: { trades: desc }
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
