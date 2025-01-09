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
    case "api_trade_history": return TubAPI.Objects.Api_trade_history
    case "candles_history_model": return TubAPI.Objects.Candles_history_model
    case "query_root": return TubAPI.Objects.Query_root
    case "subscription_root": return TubAPI.Objects.Subscription_root
    case "token_metadata_model": return TubAPI.Objects.Token_metadata_model
    case "token_stats_model": return TubAPI.Objects.Token_stats_model
    case "transaction_model": return TubAPI.Objects.Transaction_model
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
