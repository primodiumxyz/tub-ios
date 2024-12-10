import { graphql } from "./init";

// TODO: refactor to use token_purchase
export const BuyTokenMutation = graphql(`
  mutation BuyToken($wallet: String!, $token: String!, $amount: numeric!, $token_price: float8!) {
    buy_token(
      args: { user_wallet: $wallet, token_address: $token, amount_to_buy: $amount, token_price: $token_price }
    ) {
      id
    }
  }
`);

// TODO: refactor to use token_sale
export const SellTokenMutation = graphql(`
  mutation SellToken($wallet: String!, $token: String!, $amount: numeric!, $token_price: float8!) {
    sell_token(
      args: { user_wallet: $wallet, token_address: $token, amount_to_sell: $amount, token_price: $token_price }
    ) {
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
