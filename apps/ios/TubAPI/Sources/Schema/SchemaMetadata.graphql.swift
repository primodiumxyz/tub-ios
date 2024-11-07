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
    case "subscription_root": return TubAPI.Objects.Subscription_root
    case "token": return TubAPI.Objects.Token
    case "token_price_history": return TubAPI.Objects.Token_price_history
    case "formatted_tokens_model": return TubAPI.Objects.Formatted_tokens_model
    case "balance_offset_model": return TubAPI.Objects.Balance_offset_model
    case "token_price_history_offset": return TubAPI.Objects.Token_price_history_offset
    case "query_root": return TubAPI.Objects.Query_root
    case "token_transaction": return TubAPI.Objects.Token_transaction
    case "wallet_transaction": return TubAPI.Objects.Wallet_transaction
    case "token_price_history_aggregate": return TubAPI.Objects.Token_price_history_aggregate
    case "token_price_history_aggregate_fields": return TubAPI.Objects.Token_price_history_aggregate_fields
    case "hourly_swaps": return TubAPI.Objects.Hourly_swaps
    case "token_aggregate": return TubAPI.Objects.Token_aggregate
    case "token_aggregate_fields": return TubAPI.Objects.Token_aggregate_fields
    case "hourly_new_tokens": return TubAPI.Objects.Hourly_new_tokens
    case "formatted_tokens_with_performance_model": return TubAPI.Objects.Formatted_tokens_with_performance_model
    case "mutation_root": return TubAPI.Objects.Mutation_root
    case "token_mutation_response": return TubAPI.Objects.Token_mutation_response
    case "token_price_history_mutation_response": return TubAPI.Objects.Token_price_history_mutation_response
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
