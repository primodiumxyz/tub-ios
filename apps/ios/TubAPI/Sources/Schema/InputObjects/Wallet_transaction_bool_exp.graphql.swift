// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// Boolean expression to filter rows from the table "wallet_transaction". All fields are combined with a logical 'AND'.
public struct Wallet_transaction_bool_exp: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    _and: GraphQLNullable<[Wallet_transaction_bool_exp]> = nil,
    _not: GraphQLNullable<Wallet_transaction_bool_exp> = nil,
    _or: GraphQLNullable<[Wallet_transaction_bool_exp]> = nil,
    amount: GraphQLNullable<Numeric_comparison_exp> = nil,
    createdAt: GraphQLNullable<Timestamptz_comparison_exp> = nil,
    id: GraphQLNullable<Uuid_comparison_exp> = nil,
    tokenTransactions: GraphQLNullable<Token_transaction_bool_exp> = nil,
    tokenTransactionsAggregate: GraphQLNullable<Token_transaction_aggregate_bool_exp> = nil,
    wallet: GraphQLNullable<String_comparison_exp> = nil
  ) {
    __data = InputDict([
      "_and": _and,
      "_not": _not,
      "_or": _or,
      "amount": amount,
      "created_at": createdAt,
      "id": id,
      "token_transactions": tokenTransactions,
      "token_transactions_aggregate": tokenTransactionsAggregate,
      "wallet": wallet
    ])
  }

  public var _and: GraphQLNullable<[Wallet_transaction_bool_exp]> {
    get { __data["_and"] }
    set { __data["_and"] = newValue }
  }

  public var _not: GraphQLNullable<Wallet_transaction_bool_exp> {
    get { __data["_not"] }
    set { __data["_not"] = newValue }
  }

  public var _or: GraphQLNullable<[Wallet_transaction_bool_exp]> {
    get { __data["_or"] }
    set { __data["_or"] = newValue }
  }

  public var amount: GraphQLNullable<Numeric_comparison_exp> {
    get { __data["amount"] }
    set { __data["amount"] = newValue }
  }

  public var createdAt: GraphQLNullable<Timestamptz_comparison_exp> {
    get { __data["created_at"] }
    set { __data["created_at"] = newValue }
  }

  public var id: GraphQLNullable<Uuid_comparison_exp> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var tokenTransactions: GraphQLNullable<Token_transaction_bool_exp> {
    get { __data["token_transactions"] }
    set { __data["token_transactions"] = newValue }
  }

  public var tokenTransactionsAggregate: GraphQLNullable<Token_transaction_aggregate_bool_exp> {
    get { __data["token_transactions_aggregate"] }
    set { __data["token_transactions_aggregate"] = newValue }
  }

  public var wallet: GraphQLNullable<String_comparison_exp> {
    get { __data["wallet"] }
    set { __data["wallet"] = newValue }
  }
}
