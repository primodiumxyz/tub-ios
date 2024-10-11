// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct Token_price_history_aggregate_bool_exp_count: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    arguments: GraphQLNullable<[GraphQLEnum<Token_price_history_select_column>]> = nil,
    distinct: GraphQLNullable<Bool> = nil,
    filter: GraphQLNullable<Token_price_history_bool_exp> = nil,
    predicate: Int_comparison_exp
  ) {
    __data = InputDict([
      "arguments": arguments,
      "distinct": distinct,
      "filter": filter,
      "predicate": predicate
    ])
  }

  public var arguments: GraphQLNullable<[GraphQLEnum<Token_price_history_select_column>]> {
    get { __data["arguments"] }
    set { __data["arguments"] = newValue }
  }

  public var distinct: GraphQLNullable<Bool> {
    get { __data["distinct"] }
    set { __data["distinct"] = newValue }
  }

  public var filter: GraphQLNullable<Token_price_history_bool_exp> {
    get { __data["filter"] }
    set { __data["filter"] = newValue }
  }

  public var predicate: Int_comparison_exp {
    get { __data["predicate"] }
    set { __data["predicate"] = newValue }
  }
}
