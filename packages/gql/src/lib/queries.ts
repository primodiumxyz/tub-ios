import { graphql } from "./init";

export const GetWalletTokenBalanceQuery = graphql(`
  query GetWalletTokenBalance($wallet: String!, $token: String!, $start: timestamptz = "now()") {
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
    $token: String!
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
      token_price
      wallet_transaction_data {
        created_at
      }
    }
  }
`);
