import { graphql } from "./init";

// TODO: refactor to use token_purchase and token_sale
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
