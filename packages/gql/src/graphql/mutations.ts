import { graphql } from "./init";

export const AddTokenPurchaseMutation = graphql(`
  mutation AddTokenPurchase(
    $token_mint: String!
    $token_amount: numeric!
    $token_price_usd: numeric!
    $token_decimals: numeric!
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
        token_decimals: $token_decimals
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
    $token_decimals: numeric!
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
        token_decimals: $token_decimals
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

export const AddLoadingTimeMutation = graphql(`
  mutation AddLoadingTime(
    $identifier: String!
    $time_elapsed_ms: numeric!
    $attempt_number: Int!
    $total_time_ms: numeric!
    $average_time_ms: numeric!
    $user_wallet: String!
    $user_agent: String!
    $source: String
    $error_details: String
    $build: String
  ) {
    insert_loading_time_one(
      object: {
        identifier: $identifier
        time_elapsed_ms: $time_elapsed_ms
        attempt_number: $attempt_number
        total_time_ms: $total_time_ms
        average_time_ms: $average_time_ms
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

export const AddAppDwellTimeMutation = graphql(`
  mutation AddAppDwellTime(
    $dwell_time_ms: numeric!
    $user_wallet: String!
    $user_agent: String!
    $source: String
    $error_details: String
    $build: String
  ) {
    insert_app_dwell_time_one(
      object: {
        dwell_time_ms: $dwell_time_ms
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

export const AddTokenDwellTimeMutation = graphql(`
  mutation AddTokenDwellTime(
    $token_mint: String!
    $dwell_time_ms: numeric!
    $user_wallet: String!
    $user_agent: String!
    $source: String
    $error_details: String
    $build: String
  ) {
    insert_token_dwell_time_one(
      object: {
        token_mint: $token_mint
        dwell_time_ms: $dwell_time_ms
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

// Indexer
export const InsertTradeHistoryManyMutation = graphql(`
  mutation InsertTradeHistoryMany($trades: [api_trade_history_insert_input!]!) {
    insert_api_trade_history(objects: $trades) {
      affected_rows
    }
  }
`);

// Cron
export const RefreshTokenRollingStats30MinMutation = graphql(`
  mutation RefreshTokenRollingStats30Min {
    api_refresh_token_rolling_stats_30min {
      id
      success
    }
  }
`);
