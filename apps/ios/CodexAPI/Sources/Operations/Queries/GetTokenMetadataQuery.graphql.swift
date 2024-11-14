// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenMetadataQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenMetadata"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenMetadata($address: String!, $networkId: Int = 1399811149) { token(input: { address: $address, networkId: $networkId }) { __typename createdAt info { __typename name symbol description } socialLinks { __typename discord instagram telegram twitter website } } }"#
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
        .field("createdAt", Int?.self),
        .field("info", Info?.self),
        .field("socialLinks", SocialLinks?.self),
      ] }

      /// The unix timestamp for the creation of the token.
      public var createdAt: Int? { __data["createdAt"] }
      /// More metadata about the token.
      public var info: Info? { __data["info"] }
      /// Community gathered links for the socials of this token.
      public var socialLinks: SocialLinks? { __data["socialLinks"] }

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
          .field("description", String?.self),
        ] }

        /// The token name. For example, `ApeCoin`.
        public var name: String? { __data["name"] }
        /// The token symbol. For example, `APE`.
        public var symbol: String { __data["symbol"] }
        /// A description of the token.
        public var description: String? { __data["description"] }
      }

      /// Token.SocialLinks
      ///
      /// Parent Type: `SocialLinks`
      public struct SocialLinks: CodexAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.SocialLinks }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("discord", String?.self),
          .field("instagram", String?.self),
          .field("telegram", String?.self),
          .field("twitter", String?.self),
          .field("website", String?.self),
        ] }

        public var discord: String? { __data["discord"] }
        public var instagram: String? { __data["instagram"] }
        public var telegram: String? { __data["telegram"] }
        public var twitter: String? { __data["twitter"] }
        public var website: String? { __data["website"] }
      }
    }
  }
}
