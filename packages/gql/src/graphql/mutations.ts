import { graphql } from "./init";

export const AddTokenPurchaseMutation = graphql(`
  mutation AddTokenPurchase(
    $token_mint: String!
    $token_amount: numeric!
    $token_price_usd: numeric!
    $user_wallet: String!
    $user_agent: String!
    $source: String
    $error_details: String
    $build: String
  ) {
    insert_token_purchase_one(
      object: {
        token_mint: $token_mint
        token_amount: $token_amount
        token_price_usd: $token_price_usd
        user_wallet: $user_wallet
        user_agent: $user_agent
        source: $source
        error_details: $error_details
        build: $build
      }
    ) {
      id
    }
  }
`);

export const AddTokenSaleMutation = graphql(`
  mutation AddTokenSale(
    $token_mint: String!
    $token_amount: numeric!
    $token_price_usd: numeric!
    $user_wallet: String!
    $user_agent: String!
    $source: String
    $error_details: String
    $build: String
  ) {
    insert_token_sale_one(
      object: {
        token_mint: $token_mint
        token_amount: $token_amount
        token_price_usd: $token_price_usd
        user_wallet: $user_wallet
        user_agent: $user_agent
        source: $source
        error_details: $error_details
        build: $build
      }
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

// Indexer
export const InsertTradeHistoryManyMutation = graphql(`
  mutation InsertTradeHistoryMany($trades: [api_trade_history_insert_input!]!) {
    insert_api_trade_history(objects: $trades) {
      affected_rows
    }
  }
`);
