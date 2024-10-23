// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// Boolean expression to filter rows from the table "token". All fields are combined with a logical 'AND'.
public struct Token_bool_exp: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    _and: GraphQLNullable<[Token_bool_exp]> = nil,
    _not: GraphQLNullable<Token_bool_exp> = nil,
    _or: GraphQLNullable<[Token_bool_exp]> = nil,
    id: GraphQLNullable<Uuid_comparison_exp> = nil,
    mint: GraphQLNullable<String_comparison_exp> = nil,
    name: GraphQLNullable<String_comparison_exp> = nil,
    platform: GraphQLNullable<String_comparison_exp> = nil,
    supply: GraphQLNullable<Numeric_comparison_exp> = nil,
    symbol: GraphQLNullable<String_comparison_exp> = nil,
    tokenPriceHistories: GraphQLNullable<Token_price_history_bool_exp> = nil,
    tokenPriceHistoriesAggregate: GraphQLNullable<Token_price_history_aggregate_bool_exp> = nil,
    tokenTransactions: GraphQLNullable<Token_transaction_bool_exp> = nil,
    tokenTransactionsAggregate: GraphQLNullable<Token_transaction_aggregate_bool_exp> = nil,
    updatedAt: GraphQLNullable<Timestamptz_comparison_exp> = nil,
    uri: GraphQLNullable<String_comparison_exp> = nil
  ) {
    __data = InputDict([
      "_and": _and,
      "_not": _not,
      "_or": _or,
      "id": id,
      "mint": mint,
      "name": name,
      "platform": platform,
      "supply": supply,
      "symbol": symbol,
      "token_price_histories": tokenPriceHistories,
      "token_price_histories_aggregate": tokenPriceHistoriesAggregate,
      "token_transactions": tokenTransactions,
      "token_transactions_aggregate": tokenTransactionsAggregate,
      "updated_at": updatedAt,
      "uri": uri
    ])
  }

  public var _and: GraphQLNullable<[Token_bool_exp]> {
    get { __data["_and"] }
    set { __data["_and"] = newValue }
  }

  public var _not: GraphQLNullable<Token_bool_exp> {
    get { __data["_not"] }
    set { __data["_not"] = newValue }
  }

  public var _or: GraphQLNullable<[Token_bool_exp]> {
    get { __data["_or"] }
    set { __data["_or"] = newValue }
  }

  public var id: GraphQLNullable<Uuid_comparison_exp> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var mint: GraphQLNullable<String_comparison_exp> {
    get { __data["mint"] }
    set { __data["mint"] = newValue }
  }

  public var name: GraphQLNullable<String_comparison_exp> {
    get { __data["name"] }
    set { __data["name"] = newValue }
  }

  public var platform: GraphQLNullable<String_comparison_exp> {
    get { __data["platform"] }
    set { __data["platform"] = newValue }
  }

  public var supply: GraphQLNullable<Numeric_comparison_exp> {
    get { __data["supply"] }
    set { __data["supply"] = newValue }
  }

  public var symbol: GraphQLNullable<String_comparison_exp> {
    get { __data["symbol"] }
    set { __data["symbol"] = newValue }
  }

  public var tokenPriceHistories: GraphQLNullable<Token_price_history_bool_exp> {
    get { __data["token_price_histories"] }
    set { __data["token_price_histories"] = newValue }
  }

  public var tokenPriceHistoriesAggregate: GraphQLNullable<Token_price_history_aggregate_bool_exp> {
    get { __data["token_price_histories_aggregate"] }
    set { __data["token_price_histories_aggregate"] = newValue }
  }

  public var tokenTransactions: GraphQLNullable<Token_transaction_bool_exp> {
    get { __data["token_transactions"] }
    set { __data["token_transactions"] = newValue }
  }

  public var tokenTransactionsAggregate: GraphQLNullable<Token_transaction_aggregate_bool_exp> {
    get { __data["token_transactions_aggregate"] }
    set { __data["token_transactions_aggregate"] = newValue }
  }

  public var updatedAt: GraphQLNullable<Timestamptz_comparison_exp> {
    get { __data["updated_at"] }
    set { __data["updated_at"] = newValue }
  }

  public var uri: GraphQLNullable<String_comparison_exp> {
    get { __data["uri"] }
    set { __data["uri"] = newValue }
  }
}
