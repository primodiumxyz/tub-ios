import { graphql } from "./init";

export const RegisterNewTokenMutation = graphql(`
  mutation RegisterNewToken($name: String!, $symbol: String!, $supply: numeric!, $uri: String) {
    insert_token_one(object: { name: $name, symbol: $symbol, uri: $uri, supply: $supply }) {
      id
    }
  }
`);

export const UpsertManyNewTokensMutation = graphql(`
  mutation UpsertManyNewTokens($objects: [token_insert_input!]!) {
    insert_token(
      objects: $objects
      on_conflict: {
        constraint: token_mint_key
        update_columns: [
          name
          symbol
          description
          uri
          mint_burnt
          freeze_burnt
          supply
          decimals
          is_pump_token
          updated_at
        ]
        where: { _or: [{ updated_at: { _is_null: true } }, { updated_at: { _lt: NOW } }] }
      }
    ) {
      returning {
        id
        mint
      }
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

export const UpsertManyTokensAndPriceHistoryMutation = graphql(`
  mutation UpsertManyTokensAndPriceHistory($tokens: jsonb!, $priceHistory: jsonb!) {
    upsert_tokens_and_price_history(args: { tokens: $tokens, price_history: $priceHistory }) {
      id
    }
  }
`);

export const AddClientEventMutation = graphql(`
  mutation AddClientEvent(
    $user_agent: String!
    $event_name: String!
    $user_wallet: String!
    $source: String
    $metadata: jsonb
    $error_details: String
    $build: String
  ) {
    insert_analytics_client_event_one(
      object: {
        user_agent: $user_agent
        name: $event_name
        metadata: $metadata
        source: $source
        user: $user_wallet
        error_details: $error_details
        build: $build
      }
    ) {
      id
    }
  }
`);
