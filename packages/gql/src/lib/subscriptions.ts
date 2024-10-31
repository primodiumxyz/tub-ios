import { graphql } from "./init";

export const GetLatestMockTokensSubscription = graphql(`
  subscription SubLatestMockTokens($limit: Int = 10) {
    token(where: { mint: { _is_null: true } }, order_by: { updated_at: desc }, limit: $limit) {
      id
      symbol
      supply
      name
      uri
      updated_at
    }
  }
`);

export const GetTokenPriceHistorySinceSubscription = graphql(`
  subscription SubTokenPriceHistorySince($tokenId: uuid!, $since: timestamptz!) {
    token_price_history(
      where: { token: { _eq: $tokenId }, created_at: { _gte: $since } }
      limit: 100
      order_by: { created_at: desc }
    ) {
      created_at
      id
      price
      token
    }
  }
`);

export const GetLatestTokenPriceSubscription = graphql(`
  subscription SubLatestTokenPrice($tokenId: uuid!) {
    token_price_history(where: { token: { _eq: $tokenId } }, limit: 1, order_by: { created_at: desc }) {
      created_at
      price
    }
  }
`);

export const GetAllOnchainTokensPriceHistorySinceSubscription = graphql(`
  subscription SubAllOnchainTokensPriceHistorySince($since: timestamptz!) {
    token_price_history(
      where: { token_relationship: { mint: { _is_null: false } }, created_at: { _gte: $since } }
      order_by: { created_at: desc }
    ) {
      created_at
      id
      price
      token_relationship {
        mint
        name
      }
    }
  }
`);

// TODO: order by volume once integrated
export const GetFilteredTokensIntervalSubscription = graphql(`
  subscription SubFilteredTokensInterval($interval: interval = "30s", $minTrades: bigint = 0, $minVolume: numeric = 0) {
    formatted_tokens_interval(
      args: { interval: $interval }
      where: { is_pump_token: { _eq: true }, trades: { _gte: $minTrades }, volume: { _gte: $minVolume } }
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

export const GetAccountTokenBalanceSubscription = graphql(`
  subscription SubAccountTokenBalance($account: uuid!, $token: uuid!, $start: timestamptz = "now()") {
    balance: account_token_balance_ignore_interval(
      args: { account: $account, interval: "0", start: $start, token: $token }
    ) {
      value: balance
    }
  }
`);

export const GetAccountTokenBalanceIgnoreIntervalSubscription = graphql(`
  subscription SubAccountTokenBalanceIgnoreInterval(
    $account: uuid!
    $start: timestamptz = "now()"
    $interval: interval = "0"
    $token: uuid!
  ) {
    balance: account_token_balance_ignore_interval(
      args: { account: $account, interval: $interval, start: $start, token: $token }
    ) {
      value: balance
    }
  }
`);

export const GetAccountBalanceSubscription = graphql(`
  subscription SubAccountBalance($account: uuid!, $start: timestamptz = "now()") {
    balance: account_balance_ignore_interval(args: { account: $account, interval: "0", start: $start }) {
      value: balance
    }
  }
`);

export const GetAccountBalanceIgnoreIntervalSubscription = graphql(`
  subscription SubAccountBalanceIgnoreInterval(
    $account: uuid!
    $start: timestamptz = "now()"
    $interval: interval = "0"
  ) {
    balance: account_balance_ignore_interval(args: { account: $account, interval: $interval, start: $start }) {
      value: balance
    }
  }
`);

export const GetTokenPriceHistoryIntervalSubscription = graphql(`
  subscription SubTokenPriceHistoryInterval($token: uuid!, $start: timestamptz = "now()", $interval: interval = "30m") {
    token_price_history_offset(
      args: { offset: $interval }
      where: { created_at_offset: { _gte: $start }, token: { _eq: $token } }
      order_by: { created_at: asc }
    ) {
      created_at
      price
    }
  }
`);

export const GetTokenPriceHistoryIgnoreIntervalSubscription = graphql(`
  subscription SubTokenPriceHistoryIgnoreInterval(
    $token: uuid!
    $start: timestamptz = "now()"
    $interval: interval = "30s"
  ) {
    token_price_history_offset(
      args: { offset: $interval }
      where: { created_at_offset: { _lte: $start }, token: { _eq: $token } }
      order_by: { created_at: asc }
    ) {
      created_at
      price
    }
  }
`);
