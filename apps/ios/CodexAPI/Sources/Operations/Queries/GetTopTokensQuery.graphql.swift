// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTopTokensQuery: GraphQLQuery {
  public static let operationName: String = "GetTopTokens"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTopTokens($networkFilter: [Int!]! = [1399811149], $resolution: String = "60", $limit: Int = 50) { listTopTokens( networkFilter: $networkFilter resolution: $resolution limit: $limit ) { __typename address name symbol imageLargeUrl imageSmallUrl imageThumbUrl price liquidity marketCap volume topPairId exchanges { __typename address } } }"#
    ))

  public var networkFilter: [Int]
  public var resolution: GraphQLNullable<String>
  public var limit: GraphQLNullable<Int>

  public init(
    networkFilter: [Int] = [1399811149],
    resolution: GraphQLNullable<String> = "60",
    limit: GraphQLNullable<Int> = 50
  ) {
    self.networkFilter = networkFilter
    self.resolution = resolution
    self.limit = limit
  }

  public var __variables: Variables? { [
    "networkFilter": networkFilter,
    "resolution": resolution,
    "limit": limit
  ] }

  public struct Data: CodexAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("listTopTokens", [ListTopToken]?.self, arguments: [
        "networkFilter": .variable("networkFilter"),
        "resolution": .variable("resolution"),
        "limit": .variable("limit")
      ]),
    ] }

    /// Returns a list of trending tokens across any given network(s).
    public var listTopTokens: [ListTopToken]? { __data["listTopTokens"] }

    /// ListTopToken
    ///
    /// Parent Type: `TokenWithMetadata`
    public struct ListTopToken: CodexAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.TokenWithMetadata }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("address", String.self),
        .field("name", String.self),
        .field("symbol", String.self),
        .field("imageLargeUrl", String?.self),
        .field("imageSmallUrl", String?.self),
        .field("imageThumbUrl", String?.self),
        .field("price", Double.self),
        .field("liquidity", String.self),
        .field("marketCap", String?.self),
        .field("volume", String.self),
        .field("topPairId", String.self),
        .field("exchanges", [Exchange].self),
      ] }

      /// The contract address of the token.
      public var address: String { __data["address"] }
      /// The name of the token.
      public var name: String { __data["name"] }
      /// The symbol for the token.
      public var symbol: String { __data["symbol"] }
      /// The token logo URL.
      public var imageLargeUrl: String? { __data["imageLargeUrl"] }
      /// The token logo URL.
      public var imageSmallUrl: String? { __data["imageSmallUrl"] }
      /// The token logo URL.
      public var imageThumbUrl: String? { __data["imageThumbUrl"] }
      /// The token price in USD.
      public var price: Double { __data["price"] }
      /// The total liquidity of the token's top pair in USD.
      public var liquidity: String { __data["liquidity"] }
      /// The market cap of circulating supply.
      public var marketCap: String? { __data["marketCap"] }
      /// The volume over the time frame requested in USD.
      public var volume: String { __data["volume"] }
      /// The ID of the token's top pair (`pairAddress:networkId`).
      public var topPairId: String { __data["topPairId"] }
      /// The exchanges the token is listed on.
      public var exchanges: [Exchange] { __data["exchanges"] }

      /// ListTopToken.Exchange
      ///
      /// Parent Type: `Exchange`
      public struct Exchange: CodexAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Exchange }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("address", String.self),
        ] }

        /// The contract address of the exchange.
        public var address: String { __data["address"] }
      }
    }
  }
}
