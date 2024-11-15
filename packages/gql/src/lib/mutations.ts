import { graphql } from "./init";

export const BuyTokenMutation = graphql(`
  mutation BuyToken($wallet: String!, $token: String!, $amount: numeric!, $token_price: float8!) {
    buy_token(
      args: { user_wallet: $wallet, token_address: $token, amount_to_buy: $amount, token_price: $token_price }
    ) {
      id
    }
  }
`);

export const SellTokenMutation = graphql(`
  mutation SellToken($wallet: String!, $token: String!, $amount: numeric!, $token_price: float8!) {
    sell_token(
      args: { user_wallet: $wallet, token_address: $token, amount_to_sell: $amount, token_price: $token_price }
    ) {
      id
    }
  }
`);

export const AirdropNativeToWalletMutation = graphql(`
  mutation AirdropNativeToUser($wallet: String!, $amount: numeric!) {
    insert_wallet_transaction_one(object: { wallet: $wallet, amount: $amount }) {
      id
    }
  }
`);
