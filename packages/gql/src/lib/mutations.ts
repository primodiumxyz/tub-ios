import { graphql } from "./init";

export const RegisterNewTokenMutation = graphql(`
  mutation RegisterNewToken($name: String!, $symbol: String!, $supply: numeric!, $uri: String) {
    insert_token_one(object: { name: $name, symbol: $symbol, uri: $uri, supply: $supply }) {
      id
    }
  }
`);

// This mutation will ignore duplicate tokens (if we try to register a "mint" that was already inserted)
// This makes it quicker to register tokens in batches when we receive price data from websocket
export const RegisterManyNewTokensMutation = graphql(`
  mutation RegisterManyNewTokens($objects: [token_insert_input!]!) {
    insert_token(objects: $objects, on_conflict: { constraint: token_mint_key, update_columns: [] }) {
      affected_rows
    }
  }
`);

export const BuyTokenMutation = graphql(`
  mutation BuyToken($wallet: String!, $token: uuid!, $amount: numeric!, $override_token_price: numeric) {
    buy_token(
      args: { user_wallet: $wallet, token_id: $token, amount_to_buy: $amount, token_cost: $override_token_price }
    ) {
      id
    }
  }
`);

export const SellTokenMutation = graphql(`
  mutation SellToken($wallet: String!, $token: uuid!, $amount: numeric!, $override_token_price: numeric) {
    sell_token(
      args: { user_wallet: $wallet, token_id: $token, amount_to_sell: $amount, token_cost: $override_token_price }
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

export const AddTokenPriceHistoryMutation = graphql(`
  mutation AddTokenPriceHistory($token: uuid!, $price: numeric!) {
    insert_token_price_history_one(object: { token: $token, price: $price }) {
      id
    }
  }
`);

export const AddManyTokenPriceHistoryMutation = graphql(`
  mutation AddManyTokenPriceHistory($objects: [token_price_history_insert_input!]!) {
    insert_token_price_history(objects: $objects) {
      returning {
        id
      }
    }
  }
`);
