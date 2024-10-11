// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// Boolean expression to filter rows from the table "account". All fields are combined with a logical 'AND'.
public struct Account_bool_exp: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    _and: GraphQLNullable<[Account_bool_exp]> = nil,
    _not: GraphQLNullable<Account_bool_exp> = nil,
    _or: GraphQLNullable<[Account_bool_exp]> = nil,
    accountTransactions: GraphQLNullable<Account_transaction_bool_exp> = nil,
    accountTransactionsAggregate: GraphQLNullable<Account_transaction_aggregate_bool_exp> = nil,
    createdAt: GraphQLNullable<Timestamptz_comparison_exp> = nil,
    id: GraphQLNullable<Uuid_comparison_exp> = nil,
    username: GraphQLNullable<String_comparison_exp> = nil
  ) {
    __data = InputDict([
      "_and": _and,
      "_not": _not,
      "_or": _or,
      "account_transactions": accountTransactions,
      "account_transactions_aggregate": accountTransactionsAggregate,
      "created_at": createdAt,
      "id": id,
      "username": username
    ])
  }

  public var _and: GraphQLNullable<[Account_bool_exp]> {
    get { __data["_and"] }
    set { __data["_and"] = newValue }
  }

  public var _not: GraphQLNullable<Account_bool_exp> {
    get { __data["_not"] }
    set { __data["_not"] = newValue }
  }

  public var _or: GraphQLNullable<[Account_bool_exp]> {
    get { __data["_or"] }
    set { __data["_or"] = newValue }
  }

  public var accountTransactions: GraphQLNullable<Account_transaction_bool_exp> {
    get { __data["account_transactions"] }
    set { __data["account_transactions"] = newValue }
  }

  public var accountTransactionsAggregate: GraphQLNullable<Account_transaction_aggregate_bool_exp> {
    get { __data["account_transactions_aggregate"] }
    set { __data["account_transactions_aggregate"] = newValue }
  }

  public var createdAt: GraphQLNullable<Timestamptz_comparison_exp> {
    get { __data["created_at"] }
    set { __data["created_at"] = newValue }
  }

  public var id: GraphQLNullable<Uuid_comparison_exp> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var username: GraphQLNullable<String_comparison_exp> {
    get { __data["username"] }
    set { __data["username"] = newValue }
  }
}
