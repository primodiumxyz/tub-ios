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
    case "GetFormattedTokensResult": return TubAPI.Objects.GetFormattedTokensResult
    case "balance_offset_model": return TubAPI.Objects.Balance_offset_model
    case "token_price_history_offset": return TubAPI.Objects.Token_price_history_offset
    case "query_root": return TubAPI.Objects.Query_root
    case "account": return TubAPI.Objects.Account
    case "token_transaction": return TubAPI.Objects.Token_transaction
    case "account_transaction": return TubAPI.Objects.Account_transaction
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
