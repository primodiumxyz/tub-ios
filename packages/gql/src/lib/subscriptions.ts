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

// when $mintBurnt is false, this matches everything
// when $mintBurnt is true, this ensures mint_burnt is true
export const GetFilteredTokensIntervalSubscription = graphql(`
  subscription SubFilteredTokensInterval(
    $interval: interval = "30s"
    $minTrades: bigint = "0"
    $minVolume: numeric = 0
    $mintBurnt: Boolean = false
    $freezeBurnt: Boolean = false
    $minDistinctPrices: Int = 0
    $distinctPricesInterval: interval = "1m"
  ) {
    formatted_tokens_interval(
      args: {
        interval: $interval
        min_distinct_prices: $minDistinctPrices
        distinct_prices_interval: $distinctPricesInterval
      }
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

export const GetWalletTokenBalanceSubscription = graphql(`
  subscription SubWalletTokenBalance($wallet: String!, $token: uuid!, $start: timestamptz = "now()") {
    balance: wallet_token_balance_ignore_interval(
      args: { wallet: $wallet, interval: "0", start: $start, token: $token }
    ) {
      value: balance
    }
  }
`);

export const GetWalletTokenBalanceIgnoreIntervalSubscription = graphql(`
  subscription SubWalletTokenBalanceIgnoreInterval(
    $wallet: String!
    $start: timestamptz = "now()"
    $interval: interval = "0"
    $token: uuid!
  ) {
    balance: wallet_token_balance_ignore_interval(
      args: { wallet: $wallet, interval: $interval, start: $start, token: $token }
    ) {
      value: balance
    }
  }
`);

export const GetWalletBalanceSubscription = graphql(`
  subscription SubWalletBalance($wallet: String!, $start: timestamptz = "now()") {
    balance: wallet_balance_ignore_interval(args: { wallet: $wallet, interval: "0", start: $start }) {
      value: balance
    }
  }
`);

export const GetWalletBalanceIgnoreIntervalSubscription = graphql(`
  subscription SubWalletBalanceIgnoreInterval(
    $wallet: String!
    $start: timestamptz = "now()"
    $interval: interval = "0"
  ) {
    balance: wallet_balance_ignore_interval(args: { wallet: $wallet, interval: $interval, start: $start }) {
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
