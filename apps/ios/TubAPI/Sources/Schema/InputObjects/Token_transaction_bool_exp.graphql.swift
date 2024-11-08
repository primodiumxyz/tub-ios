// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// Boolean expression to filter rows from the table "token_transaction". All fields are combined with a logical 'AND'.
public struct Token_transaction_bool_exp: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    _and: GraphQLNullable<[Token_transaction_bool_exp]> = nil,
    _not: GraphQLNullable<Token_transaction_bool_exp> = nil,
    _or: GraphQLNullable<[Token_transaction_bool_exp]> = nil,
    amount: GraphQLNullable<Numeric_comparison_exp> = nil,
    id: GraphQLNullable<Uuid_comparison_exp> = nil,
    token: GraphQLNullable<Uuid_comparison_exp> = nil,
    tokenData: GraphQLNullable<Token_bool_exp> = nil,
    tokenPrice: GraphQLNullable<Token_price_history_bool_exp> = nil,
    walletTransaction: GraphQLNullable<Uuid_comparison_exp> = nil,
    walletTransactionData: GraphQLNullable<Wallet_transaction_bool_exp> = nil
  ) {
    __data = InputDict([
      "_and": _and,
      "_not": _not,
      "_or": _or,
      "amount": amount,
      "id": id,
      "token": token,
      "token_data": tokenData,
      "token_price": tokenPrice,
      "wallet_transaction": walletTransaction,
      "wallet_transaction_data": walletTransactionData
    ])
  }

  public var _and: GraphQLNullable<[Token_transaction_bool_exp]> {
    get { __data["_and"] }
    set { __data["_and"] = newValue }
  }

  public var _not: GraphQLNullable<Token_transaction_bool_exp> {
    get { __data["_not"] }
    set { __data["_not"] = newValue }
  }

  public var _or: GraphQLNullable<[Token_transaction_bool_exp]> {
    get { __data["_or"] }
    set { __data["_or"] = newValue }
  }

  public var amount: GraphQLNullable<Numeric_comparison_exp> {
    get { __data["amount"] }
    set { __data["amount"] = newValue }
  }

  public var id: GraphQLNullable<Uuid_comparison_exp> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var token: GraphQLNullable<Uuid_comparison_exp> {
    get { __data["token"] }
    set { __data["token"] = newValue }
  }

  public var tokenData: GraphQLNullable<Token_bool_exp> {
    get { __data["token_data"] }
    set { __data["token_data"] = newValue }
  }

  public var tokenPrice: GraphQLNullable<Token_price_history_bool_exp> {
    get { __data["token_price"] }
    set { __data["token_price"] = newValue }
  }

  public var walletTransaction: GraphQLNullable<Uuid_comparison_exp> {
    get { __data["wallet_transaction"] }
    set { __data["wallet_transaction"] = newValue }
  }

  public var walletTransactionData: GraphQLNullable<Wallet_transaction_bool_exp> {
    get { __data["wallet_transaction_data"] }
    set { __data["wallet_transaction_data"] = newValue }
  }
}
