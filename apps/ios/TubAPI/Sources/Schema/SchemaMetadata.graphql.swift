// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == TubAPI.SchemaMetadata {}

public protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == TubAPI.SchemaMetadata {}

public protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == TubAPI.SchemaMetadata {}

public protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == TubAPI.SchemaMetadata {}

public enum SchemaMetadata: ApolloAPI.SchemaMetadata {
  public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

  public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
    switch typename {
    case "api_refresh_history": return TubAPI.Objects.Api_refresh_history
    case "api_trade_history": return TubAPI.Objects.Api_trade_history
    case "api_trade_history_mutation_response": return TubAPI.Objects.Api_trade_history_mutation_response
    case "app_dwell_time": return TubAPI.Objects.App_dwell_time
    case "candles_history_model": return TubAPI.Objects.Candles_history_model
    case "loading_time": return TubAPI.Objects.Loading_time
    case "mutation_root": return TubAPI.Objects.Mutation_root
    case "query_root": return TubAPI.Objects.Query_root
    case "subscription_root": return TubAPI.Objects.Subscription_root
    case "token_dwell_time": return TubAPI.Objects.Token_dwell_time
    case "token_purchase": return TubAPI.Objects.Token_purchase
    case "token_rolling_stats_30min_model": return TubAPI.Objects.Token_rolling_stats_30min_model
    case "token_sale": return TubAPI.Objects.Token_sale
    case "transaction_analytics_model": return TubAPI.Objects.Transaction_analytics_model
    case "transaction_model": return TubAPI.Objects.Transaction_model
    case "wallet_token_pnl_model": return TubAPI.Objects.Wallet_token_pnl_model
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
