import { graphql } from "./init";

export const GetLatestMockTokensSubscription = graphql(`
  subscription SubLatestMockTokens($limit: Int = 10) {
    token(where: { mint: { _is_null: true } }, order_by: { updated_at: desc }, limit: $limit) {
      id
      symbol
      supply
      name
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

export const GetFilteredTokensSubscription = graphql(`
  subscription SubFilteredTokens($since: timestamptz!, $minTrades: bigint!, $minIncreasePct: float8!) {
    GetFormattedTokens(
      where: { created_at: { _gte: $since }, trades: { _gte: $minTrades }, increase_pct: { _gte: $minIncreasePct } }
    ) {
      token_id
      mint
      name
      symbol
      latest_price
      increase_pct
      trades
      created_at
    }
  }
`);

//TODO: REMOVE
// export const GetAccountTokenBalanceCreditSubscription = graphql(`
//   subscription SubAccountTokenBalanceCredit($accountId: uuid!, $tokenId: uuid!) {
//     token_transaction_aggregate(
//       where: {
//         account_transaction_data: { account: { _eq: $accountId } }
//         token: { _eq: $tokenId }
//         transaction_type: { _eq: "credit" }
//       }
//     ) {
//       aggregate {
//         sum {
//           amount
//         }
//       }
//     }
//   }
// `);

// export const GetAccountTokenBalanceDebitSubscription = graphql(`
//   subscription SubAccountTokenBalanceDebit($accountId: uuid!, $tokenId: uuid!) {
//     token_transaction_aggregate(
//       where: {
//         account_transaction_data: { account: { _eq: $accountId } }
//         token: { _eq: $tokenId }
//         transaction_type: { _eq: "debit" }
//       }
//     ) {
//       aggregate {
//         sum {
//           amount
//         }
//       }
//     }
//   }
// `);


export const GetAccountBalanceSubscription = graphql(`
  subscription SubAccountBalanceIgnoreInterval($account: uuid!, $start: timestamptz = "now()") {
      balance: account_balance_ignore_interval(args: {account: $account, interval: "0", start: $start}) {
      value: balance
    }
  }
`);

export const GetAccountBalanceIgnoreIntervalSubscription = graphql(`
  subscription SubAccountBalanceIgnoreInterval($account: uuid!, $start: timestamptz = "now()", $interval: interval = "0") {
      balance: account_balance_ignore_interval(args: {account: $account, interval: $interval, start: $start}) {
      value: balance
    }
  }
`);

export const GetTokenPriceHistoryIntervalSubscription = graphql(`
  subscription SubTokenPriceHistoryInterval($token: uuid, $start: timestamptz = "now()", $interval: interval = "30m") {
    token_price_history_offset(args: {offset: $interval}, where: {created_at_offset: {_gte: $start}, token: {_eq: $token}}, order_by: {created_at: desc}) {
      created_at
      price
    }
  }
`);

export const GetTokenPriceHistoryIgnoreIntervalSubscription = graphql(`
  subscription SubTokenPriceHistoryIgnoreInterval($token: uuid, $start: timestamptz = "now()", $interval: interval = "30m") {
    token_price_history_offset(args: {offset: $interval}, where: {created_at_offset: {_lte: $start}, token: {_eq: $token}}, order_by: {created_at: desc}) {
      created_at
      price
    }
  }
`);
