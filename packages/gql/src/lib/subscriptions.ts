import { graphql } from "./init";

export const LatestMockTokensSubscription = graphql(`
  subscription SubLatestMockTokens($limit: Int = 10) {
    token(where: { mint: { _is_null: true } }, order_by: { updated_at: desc }, limit: $limit) {
      id
      symbol
      supply
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

export const GetAccountBalanceCreditSubscription = graphql(`
  subscription SubAccountBalanceCredit($accountId: uuid!) {
    account_transaction_aggregate(where: { account: { _eq: $accountId }, transaction_type: { _eq: "credit" } }) {
      aggregate {
        sum {
          amount
        }
      }
    }
  }
`);

export const GetAccountBalanceDebitSubscription = graphql(`
  subscription SubAccountBalanceDebit($accountId: uuid!) {
    account_transaction_aggregate(where: { account: { _eq: $accountId }, transaction_type: { _eq: "debit" } }) {
      aggregate {
        sum {
          amount
        }
      }
    }
  }
`);

export const GetAccountTokenCreditSubscription = graphql(`
  subscription SubAccountTokenCredit($accountId: uuid!, $tokenId: uuid!) {
    token_transaction_aggregate(
      where: {
        account_transaction_data: { account: { _eq: $accountId } }
        token: { _eq: $tokenId }
        transaction_type: { _eq: "credit" }
      }
    ) {
      aggregate {
        sum {
          amount
        }
      }
    }
  }
`);

export const GetAccountTokenDebitSubscription = graphql(`
  subscription SubAccountTokenDebit($accountId: uuid!, $tokenId: uuid!) {
    token_transaction_aggregate(
      where: {
        account_transaction_data: { account: { _eq: $accountId } }
        token: { _eq: $tokenId }
        transaction_type: { _eq: "debit" }
      }
    ) {
      aggregate {
        sum {
          amount
        }
      }
    }
  }
`);