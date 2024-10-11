// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// on_conflict condition type for table "token_price_history"
public struct Token_price_history_on_conflict: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    constraint: GraphQLEnum<Token_price_history_constraint>,
    updateColumns: [GraphQLEnum<Token_price_history_update_column>]? = nil,
    `where`: GraphQLNullable<Token_price_history_bool_exp> = nil
  ) {
    __data = InputDict([
      "constraint": constraint,
      "update_columns": updateColumns,
      "where": `where`
    ])
  }

  public var constraint: GraphQLEnum<Token_price_history_constraint> {
    get { __data["constraint"] }
    set { __data["constraint"] = newValue }
  }

  public var updateColumns: [GraphQLEnum<Token_price_history_update_column>]? {
    get { __data["update_columns"] }
    set { __data["update_columns"] = newValue }
  }

  public var `where`: GraphQLNullable<Token_price_history_bool_exp> {
    get { __data["where"] }
    set { __data["where"] = newValue }
  }
}
