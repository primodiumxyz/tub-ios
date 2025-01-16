// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetBulkTokenMetadataQuery: GraphQLQuery {
  public static let operationName: String = "GetBulkTokenMetadata"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetBulkTokenMetadata($tokens: [String!]!) { token_rolling_stats_30min(where: { mint: { _in: $tokens } }) { __typename mint name symbol description image_uri external_url decimals } }"#
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
      .field("token_rolling_stats_30min", [Token_rolling_stats_30min].self, arguments: ["where": ["mint": ["_in": .variable("tokens")]]]),
    ] }

    public var token_rolling_stats_30min: [Token_rolling_stats_30min] { __data["token_rolling_stats_30min"] }

    /// Token_rolling_stats_30min
    ///
    /// Parent Type: `Token_rolling_stats_30min_model`
    public struct Token_rolling_stats_30min: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_rolling_stats_30min_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("mint", String.self),
        .field("name", String.self),
        .field("symbol", String.self),
        .field("description", String.self),
        .field("image_uri", String?.self),
        .field("external_url", String?.self),
        .field("decimals", TubAPI.Numeric.self),
      ] }

      public var mint: String { __data["mint"] }
      public var name: String { __data["name"] }
      public var symbol: String { __data["symbol"] }
      public var description: String { __data["description"] }
      public var image_uri: String? { __data["image_uri"] }
      public var external_url: String? { __data["external_url"] }
      public var decimals: TubAPI.Numeric { __data["decimals"] }
    }
  }
}
