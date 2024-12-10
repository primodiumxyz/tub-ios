import { graphql } from "./init";

export const AddTokenPurchaseMutation = graphql(`
  mutation AddTokenPurchase($insert_token_purchase_one: token_purchase_insert_input!) {
    insert_token_purchase_one(object: $insert_token_purchase_one) {
      id
    }
  }
`);

export const AddTokenSaleMutation = graphql(`
  mutation AddTokenSale($insert_token_sale_one: token_sale_insert_input!) {
    insert_token_sale_one(object: $insert_token_sale_one) {
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
