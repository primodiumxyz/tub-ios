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
