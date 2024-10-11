// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting data into table "account"
public struct Account_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    accountTransactions: GraphQLNullable<Account_transaction_arr_rel_insert_input> = nil,
    createdAt: GraphQLNullable<Timestamptz> = nil,
    id: GraphQLNullable<Uuid> = nil,
    username: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "account_transactions": accountTransactions,
      "created_at": createdAt,
      "id": id,
      "username": username
    ])
  }

  public var accountTransactions: GraphQLNullable<Account_transaction_arr_rel_insert_input> {
    get { __data["account_transactions"] }
    set { __data["account_transactions"] = newValue }
  }

  public var createdAt: GraphQLNullable<Timestamptz> {
    get { __data["created_at"] }
    set { __data["created_at"] = newValue }
  }

  public var id: GraphQLNullable<Uuid> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var username: GraphQLNullable<String> {
    get { __data["username"] }
    set { __data["username"] = newValue }
  }
}
