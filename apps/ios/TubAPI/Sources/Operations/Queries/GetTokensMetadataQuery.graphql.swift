// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokensMetadataQuery: GraphQLQuery {
  public static let operationName: String = "GetTokensMetadata"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokensMetadata($tokens: [String!]!) { token_metadata_formatted(where: { mint: { _in: $tokens } }) { __typename mint name symbol image_uri } }"#
    ))

  public var tokens: [String]

  public init(tokens: [String]) {
    self.tokens = tokens
  }

  public var __variables: Variables? { ["tokens": tokens] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_metadata_formatted", [Token_metadata_formatted].self, arguments: ["where": ["mint": ["_in": .variable("tokens")]]]),
    ] }

    public var token_metadata_formatted: [Token_metadata_formatted] { __data["token_metadata_formatted"] }

    /// Token_metadata_formatted
    ///
    /// Parent Type: `Token_metadata_model`
    public struct Token_metadata_formatted: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_metadata_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("mint", String.self),
        .field("name", String.self),
        .field("symbol", String.self),
        .field("image_uri", String?.self),
      ] }

      public var mint: String { __data["mint"] }
      public var name: String { __data["name"] }
      public var symbol: String { __data["symbol"] }
      public var image_uri: String? { __data["image_uri"] }
    }
  }
}
