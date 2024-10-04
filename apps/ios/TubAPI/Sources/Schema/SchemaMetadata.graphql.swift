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
    case "query_root": return TubAPI.Objects.Query_root
    case "account": return TubAPI.Objects.Account
    case "account_transaction_aggregate": return TubAPI.Objects.Account_transaction_aggregate
    case "account_transaction_aggregate_fields": return TubAPI.Objects.Account_transaction_aggregate_fields
    case "account_transaction_sum_fields": return TubAPI.Objects.Account_transaction_sum_fields
    case "token_transaction_aggregate": return TubAPI.Objects.Token_transaction_aggregate
    case "token_transaction_aggregate_fields": return TubAPI.Objects.Token_transaction_aggregate_fields
    case "token_transaction_sum_fields": return TubAPI.Objects.Token_transaction_sum_fields
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
