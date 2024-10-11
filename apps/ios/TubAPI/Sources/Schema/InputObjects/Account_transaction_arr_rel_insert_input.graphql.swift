// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting array relation for remote table "account_transaction"
public struct Account_transaction_arr_rel_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    data: [Account_transaction_insert_input],
    onConflict: GraphQLNullable<Account_transaction_on_conflict> = nil
  ) {
    __data = InputDict([
      "data": data,
      "on_conflict": onConflict
    ])
  }

  public var data: [Account_transaction_insert_input] {
    get { __data["data"] }
    set { __data["data"] = newValue }
  }

  /// upsert condition
  public var onConflict: GraphQLNullable<Account_transaction_on_conflict> {
    get { __data["on_conflict"] }
    set { __data["on_conflict"] = newValue }
  }
}
