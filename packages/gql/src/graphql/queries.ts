import { graphql } from "./init";

export const GetWalletTransactionsQuery = graphql(`
  query GetWalletTransactions($wallet: String!) {
    transactions(where: { user_wallet: { _eq: $wallet }, success: { _eq: true } }, order_by: { created_at: desc }) {
      id
      created_at
      token_mint
      token_amount
      token_price_usd
      token_value_usd
    }
  }
`);
