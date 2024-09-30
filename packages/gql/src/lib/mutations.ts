import { graphql } from "./init";

export const RegisterNewUserMutation = graphql(`
  mutation RegisterNewUser($username: String!, $amount: numeric!) {
    insert_account_one(
      object: { account_transactions: { data: { amount: $amount, transaction_type: "credit" } }, username: $username }
    ) {
      id
    }
  }
`);

export const RegisterNewTokenMutation = graphql(`
  mutation RegisterNewToken($name: String!, $symbol: String!, $supply: numeric!, $uri: String) {
    insert_token_one(object: { name: $name, symbol: $symbol, uri: $uri, supply: $supply }) {
      id
    }
  }
`);

export const BuyTokenMutation = graphql(` 
  mutation BuyToken($account: uuid!, $token: uuid!, $amount: numeric!, $override_token_price: numeric) {
    buy_token(
      args: { account_id: $account, token_id: $token, amount_to_buy: $amount, token_cost: $override_token_price }
    ) {
      id
    }
  }
`);

export const SellTokenMutation = graphql(`
  mutation SellToken($account: uuid!, $token: uuid!, $amount: numeric!, $override_token_price: numeric) {
    sell_token(
      args: { account_id: $account, token_id: $token, amount_to_sell: $amount, token_cost: $override_token_price }
    ) {
      id
    }
  }
`);

export const AirdropNativeToUserMutation = graphql(`
  mutation AirdropNativeToUser($account: uuid!, $amount: numeric!) {
    insert_account_transaction_one(object: { account: $account, amount: $amount, transaction_type: "credit" }) {
      id
    }
  }
`);
  