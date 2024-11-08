// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting data into table "token"
public struct Token_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    createdAt: GraphQLNullable<Timestamptz> = nil,
    decimals: GraphQLNullable<Int> = nil,
    description: GraphQLNullable<String> = nil,
    freezeBurnt: GraphQLNullable<Bool> = nil,
    id: GraphQLNullable<Uuid> = nil,
    isPumpToken: GraphQLNullable<Bool> = nil,
    mint: GraphQLNullable<String> = nil,
    mintBurnt: GraphQLNullable<Bool> = nil,
    name: GraphQLNullable<String> = nil,
    platform: GraphQLNullable<String> = nil,
    supply: GraphQLNullable<Numeric> = nil,
    symbol: GraphQLNullable<String> = nil,
    tokenPriceHistories: GraphQLNullable<Token_price_history_arr_rel_insert_input> = nil,
    tokenTransactions: GraphQLNullable<Token_transaction_arr_rel_insert_input> = nil,
    updatedAt: GraphQLNullable<Timestamptz> = nil,
    uri: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "created_at": createdAt,
      "decimals": decimals,
      "description": description,
      "freeze_burnt": freezeBurnt,
      "id": id,
      "is_pump_token": isPumpToken,
      "mint": mint,
      "mint_burnt": mintBurnt,
      "name": name,
      "platform": platform,
      "supply": supply,
      "symbol": symbol,
      "token_price_histories": tokenPriceHistories,
      "token_transactions": tokenTransactions,
      "updated_at": updatedAt,
      "uri": uri
    ])
  }

  public var createdAt: GraphQLNullable<Timestamptz> {
    get { __data["created_at"] }
    set { __data["created_at"] = newValue }
  }

  public var decimals: GraphQLNullable<Int> {
    get { __data["decimals"] }
    set { __data["decimals"] = newValue }
  }

  public var description: GraphQLNullable<String> {
    get { __data["description"] }
    set { __data["description"] = newValue }
  }

  public var freezeBurnt: GraphQLNullable<Bool> {
    get { __data["freeze_burnt"] }
    set { __data["freeze_burnt"] = newValue }
  }

  public var id: GraphQLNullable<Uuid> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var isPumpToken: GraphQLNullable<Bool> {
    get { __data["is_pump_token"] }
    set { __data["is_pump_token"] = newValue }
  }

  /// token mint address (only for real tokens)
  public var mint: GraphQLNullable<String> {
    get { __data["mint"] }
    set { __data["mint"] = newValue }
  }

  public var mintBurnt: GraphQLNullable<Bool> {
    get { __data["mint_burnt"] }
    set { __data["mint_burnt"] = newValue }
  }

  public var name: GraphQLNullable<String> {
    get { __data["name"] }
    set { __data["name"] = newValue }
  }

  public var platform: GraphQLNullable<String> {
    get { __data["platform"] }
    set { __data["platform"] = newValue }
  }

  public var supply: GraphQLNullable<Numeric> {
    get { __data["supply"] }
    set { __data["supply"] = newValue }
  }

  public var symbol: GraphQLNullable<String> {
    get { __data["symbol"] }
    set { __data["symbol"] = newValue }
  }

  public var tokenPriceHistories: GraphQLNullable<Token_price_history_arr_rel_insert_input> {
    get { __data["token_price_histories"] }
    set { __data["token_price_histories"] = newValue }
  }

  public var tokenTransactions: GraphQLNullable<Token_transaction_arr_rel_insert_input> {
    get { __data["token_transactions"] }
    set { __data["token_transactions"] = newValue }
  }

  public var updatedAt: GraphQLNullable<Timestamptz> {
    get { __data["updated_at"] }
    set { __data["updated_at"] = newValue }
  }

  public var uri: GraphQLNullable<String> {
    get { __data["uri"] }
    set { __data["uri"] = newValue }
  }
}
