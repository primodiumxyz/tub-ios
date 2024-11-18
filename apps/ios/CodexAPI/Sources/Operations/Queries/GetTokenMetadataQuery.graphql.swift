// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenMetadataQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenMetadata"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenMetadata($address: String!, $networkId: Int = 1399811149) { token(input: { address: $address, networkId: $networkId }) { __typename info { __typename name symbol imageLargeUrl imageSmallUrl imageThumbUrl } } }"#
    ))

  public var address: String
  public var networkId: GraphQLNullable<Int>

  public init(
    address: String,
    networkId: GraphQLNullable<Int> = 1399811149
  ) {
    self.address = address
    self.networkId = networkId
  }

  public var __variables: Variables? { [
    "address": address,
    "networkId": networkId
  ] }

  public struct Data: CodexAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token", Token.self, arguments: ["input": [
        "address": .variable("address"),
        "networkId": .variable("networkId")
      ]]),
    ] }

    /// Find a single token by its address & network id.
    public var token: Token { __data["token"] }

    /// Token
    ///
    /// Parent Type: `EnhancedToken`
    public struct Token: CodexAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.EnhancedToken }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("info", Info?.self),
      ] }

      /// More metadata about the token.
      public var info: Info? { __data["info"] }

      /// Token.Info
      ///
      /// Parent Type: `TokenInfo`
      public struct Info: CodexAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.TokenInfo }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("name", String?.self),
          .field("symbol", String.self),
          .field("imageLargeUrl", String?.self),
          .field("imageSmallUrl", String?.self),
          .field("imageThumbUrl", String?.self),
        ] }

        /// The token name. For example, `ApeCoin`.
        public var name: String? { __data["name"] }
        /// The token symbol. For example, `APE`.
        public var symbol: String { __data["symbol"] }
        /// The large token logo URL.
        public var imageLargeUrl: String? { __data["imageLargeUrl"] }
        /// The small token logo URL.
        public var imageSmallUrl: String? { __data["imageSmallUrl"] }
        /// The thumbnail token logo URL.
        public var imageThumbUrl: String? { __data["imageThumbUrl"] }
      }
    }
  }
}
