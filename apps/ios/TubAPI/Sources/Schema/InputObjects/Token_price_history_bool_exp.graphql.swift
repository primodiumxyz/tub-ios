// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// Boolean expression to filter rows from the table "token_price_history". All fields are combined with a logical 'AND'.
public struct Token_price_history_bool_exp: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    _and: GraphQLNullable<[Token_price_history_bool_exp]> = nil,
    _not: GraphQLNullable<Token_price_history_bool_exp> = nil,
    _or: GraphQLNullable<[Token_price_history_bool_exp]> = nil,
    amountIn: GraphQLNullable<Numeric_comparison_exp> = nil,
    amountOut: GraphQLNullable<Numeric_comparison_exp> = nil,
    createdAt: GraphQLNullable<Timestamptz_comparison_exp> = nil,
    id: GraphQLNullable<Uuid_comparison_exp> = nil,
    internalTokenTransactionRef: GraphQLNullable<Uuid_comparison_exp> = nil,
    maxAmountIn: GraphQLNullable<Numeric_comparison_exp> = nil,
    minAmountOut: GraphQLNullable<Numeric_comparison_exp> = nil,
    price: GraphQLNullable<Numeric_comparison_exp> = nil,
    token: GraphQLNullable<Uuid_comparison_exp> = nil,
    tokenRelationship: GraphQLNullable<Token_bool_exp> = nil,
    tokenTransaction: GraphQLNullable<Token_transaction_bool_exp> = nil
  ) {
    __data = InputDict([
      "_and": _and,
      "_not": _not,
      "_or": _or,
      "amount_in": amountIn,
      "amount_out": amountOut,
      "created_at": createdAt,
      "id": id,
      "internal_token_transaction_ref": internalTokenTransactionRef,
      "max_amount_in": maxAmountIn,
      "min_amount_out": minAmountOut,
      "price": price,
      "token": token,
      "token_relationship": tokenRelationship,
      "token_transaction": tokenTransaction
    ])
  }

  public var _and: GraphQLNullable<[Token_price_history_bool_exp]> {
    get { __data["_and"] }
    set { __data["_and"] = newValue }
  }

  public var _not: GraphQLNullable<Token_price_history_bool_exp> {
    get { __data["_not"] }
    set { __data["_not"] = newValue }
  }

  public var _or: GraphQLNullable<[Token_price_history_bool_exp]> {
    get { __data["_or"] }
    set { __data["_or"] = newValue }
  }

  public var amountIn: GraphQLNullable<Numeric_comparison_exp> {
    get { __data["amount_in"] }
    set { __data["amount_in"] = newValue }
  }

  public var amountOut: GraphQLNullable<Numeric_comparison_exp> {
    get { __data["amount_out"] }
    set { __data["amount_out"] = newValue }
  }

  public var createdAt: GraphQLNullable<Timestamptz_comparison_exp> {
    get { __data["created_at"] }
    set { __data["created_at"] = newValue }
  }

  public var id: GraphQLNullable<Uuid_comparison_exp> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var internalTokenTransactionRef: GraphQLNullable<Uuid_comparison_exp> {
    get { __data["internal_token_transaction_ref"] }
    set { __data["internal_token_transaction_ref"] = newValue }
  }

  public var maxAmountIn: GraphQLNullable<Numeric_comparison_exp> {
    get { __data["max_amount_in"] }
    set { __data["max_amount_in"] = newValue }
  }

  public var minAmountOut: GraphQLNullable<Numeric_comparison_exp> {
    get { __data["min_amount_out"] }
    set { __data["min_amount_out"] = newValue }
  }

  public var price: GraphQLNullable<Numeric_comparison_exp> {
    get { __data["price"] }
    set { __data["price"] = newValue }
  }

  public var token: GraphQLNullable<Uuid_comparison_exp> {
    get { __data["token"] }
    set { __data["token"] = newValue }
  }

  public var tokenRelationship: GraphQLNullable<Token_bool_exp> {
    get { __data["token_relationship"] }
    set { __data["token_relationship"] = newValue }
  }

  public var tokenTransaction: GraphQLNullable<Token_transaction_bool_exp> {
    get { __data["token_transaction"] }
    set { __data["token_transaction"] = newValue }
  }
}
