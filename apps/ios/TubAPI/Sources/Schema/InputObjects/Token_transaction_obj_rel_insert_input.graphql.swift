// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting object relation for remote table "token_transaction"
public struct Token_transaction_obj_rel_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    data: Token_transaction_insert_input,
    onConflict: GraphQLNullable<Token_transaction_on_conflict> = nil
  ) {
    __data = InputDict([
      "data": data,
      "on_conflict": onConflict
    ])
  }

  public var data: Token_transaction_insert_input {
    get { __data["data"] }
    set { __data["data"] = newValue }
  }

  /// upsert condition
  public var onConflict: GraphQLNullable<Token_transaction_on_conflict> {
    get { __data["on_conflict"] }
    set { __data["on_conflict"] = newValue }
  }
}
