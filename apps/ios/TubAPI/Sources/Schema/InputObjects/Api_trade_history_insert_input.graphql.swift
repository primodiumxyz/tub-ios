// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting data into table "api.trade_history"
public struct Api_trade_history_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    createdAt: GraphQLNullable<Timestamptz> = nil,
    id: GraphQLNullable<Uuid> = nil,
    tokenMetadata: GraphQLNullable<Token_metadata_scalar> = nil,
    tokenMint: GraphQLNullable<String> = nil,
    tokenPriceUsd: GraphQLNullable<Numeric> = nil,
    volumeUsd: GraphQLNullable<Numeric> = nil
  ) {
    __data = InputDict([
      "created_at": createdAt,
      "id": id,
      "token_metadata": tokenMetadata,
      "token_mint": tokenMint,
      "token_price_usd": tokenPriceUsd,
      "volume_usd": volumeUsd
    ])
  }

  public var createdAt: GraphQLNullable<Timestamptz> {
    get { __data["created_at"] }
    set { __data["created_at"] = newValue }
  }

  public var id: GraphQLNullable<Uuid> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var tokenMetadata: GraphQLNullable<Token_metadata_scalar> {
    get { __data["token_metadata"] }
    set { __data["token_metadata"] = newValue }
  }

  public var tokenMint: GraphQLNullable<String> {
    get { __data["token_mint"] }
    set { __data["token_mint"] = newValue }
  }

  public var tokenPriceUsd: GraphQLNullable<Numeric> {
    get { __data["token_price_usd"] }
    set { __data["token_price_usd"] = newValue }
  }

  public var volumeUsd: GraphQLNullable<Numeric> {
    get { __data["volume_usd"] }
    set { __data["volume_usd"] = newValue }
  }
}
