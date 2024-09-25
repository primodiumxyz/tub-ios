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

export const GetAllTokensQuery = graphql(`
  query GetAllTokens {
    token {
      id
      name
      symbol
      updated_at
      supply
      uri
    }
  }
`);

export const GetAccountTokenCreditQuery = graphql(`
  query GetAccountTokenTransactions($accountId: uuid!, $tokenId: uuid!) {
    token_transaction_aggregate(
      where: {
        account_transaction_relationship: { account: { _eq: $accountId } }
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

export const GetAccountTokenDebitQuery = graphql(`
  query GetAccountTokenTransactions($accountId: uuid!, $tokenId: uuid!) {
    token_transaction_aggregate(
      where: {
        account_transaction_relationship: { account: { _eq: $accountId } }
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

export const GetLatestTokenPriceQuery = graphql(`
  query GetLatestTokenPrice($tokenId: uuid!) {
    token_price_history(where: {token: {_eq: $tokenId}}, order_by: {created_at: desc}, limit: 1) {
      created_at
      id
      price
      token
    }
  }
`);


