// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting data into table "token_purchase"
public struct Token_purchase_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    build: GraphQLNullable<String> = nil,
    createdAt: GraphQLNullable<Timestamptz> = nil,
    errorDetails: GraphQLNullable<String> = nil,
    id: GraphQLNullable<Uuid> = nil,
    source: GraphQLNullable<String> = nil,
    tokenAmount: GraphQLNullable<Numeric> = nil,
    tokenMint: GraphQLNullable<String> = nil,
    tokenPriceUsd: GraphQLNullable<Numeric> = nil,
    userAgent: GraphQLNullable<String> = nil,
    userWallet: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "build": build,
      "created_at": createdAt,
      "error_details": errorDetails,
      "id": id,
      "source": source,
      "token_amount": tokenAmount,
      "token_mint": tokenMint,
      "token_price_usd": tokenPriceUsd,
      "user_agent": userAgent,
      "user_wallet": userWallet
    ])
  }

  public var build: GraphQLNullable<String> {
    get { __data["build"] }
    set { __data["build"] = newValue }
  }

  public var createdAt: GraphQLNullable<Timestamptz> {
    get { __data["created_at"] }
    set { __data["created_at"] = newValue }
  }

  public var errorDetails: GraphQLNullable<String> {
    get { __data["error_details"] }
    set { __data["error_details"] = newValue }
  }

  public var id: GraphQLNullable<Uuid> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var source: GraphQLNullable<String> {
    get { __data["source"] }
    set { __data["source"] = newValue }
  }

  public var tokenAmount: GraphQLNullable<Numeric> {
    get { __data["token_amount"] }
    set { __data["token_amount"] = newValue }
  }

  public var tokenMint: GraphQLNullable<String> {
    get { __data["token_mint"] }
    set { __data["token_mint"] = newValue }
  }

  public var tokenPriceUsd: GraphQLNullable<Numeric> {
    get { __data["token_price_usd"] }
    set { __data["token_price_usd"] = newValue }
  }

  public var userAgent: GraphQLNullable<String> {
    get { __data["user_agent"] }
    set { __data["user_agent"] = newValue }
  }

  public var userWallet: GraphQLNullable<String> {
    get { __data["user_wallet"] }
    set { __data["user_wallet"] = newValue }
  }
}
