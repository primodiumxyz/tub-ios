import { graphql } from "./init";

export const BuyTokenMutation = graphql(`
  mutation BuyToken($wallet: String!, $token: String!, $amount: numeric!, $override_token_price: numeric) {
    buy_token(
      args: { user_wallet: $wallet, token: $token, amount_to_buy: $amount, token_cost: $override_token_price }
    ) {
      id
    }
  }
`);

export const SellTokenMutation = graphql(`
  mutation SellToken($wallet: String!, $token: String!, $amount: numeric!, $override_token_price: numeric) {
    sell_token(
      args: { user_wallet: $wallet, token: $token, amount_to_sell: $amount, token_cost: $override_token_price }
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
