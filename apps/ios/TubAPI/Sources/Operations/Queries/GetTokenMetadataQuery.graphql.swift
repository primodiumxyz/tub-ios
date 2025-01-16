// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenMetadataQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenMetadata"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenMetadata($token: String!) { token_rolling_stats_30min(where: { mint: { _eq: $token } }) { __typename mint name symbol image_uri supply decimals description external_url is_pump_token } }"#
    ))

  public var token: String

  public init(token: String) {
    self.token = token
  }

  public var __variables: Variables? { ["token": token] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_rolling_stats_30min", [Token_rolling_stats_30min].self, arguments: ["where": ["mint": ["_eq": .variable("token")]]]),
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
        .field("image_uri", String?.self),
        .field("supply", TubAPI.Numeric?.self),
        .field("decimals", TubAPI.Numeric.self),
        .field("description", String.self),
        .field("external_url", String?.self),
        .field("is_pump_token", Bool.self),
      ] }

      public var mint: String { __data["mint"] }
      public var name: String { __data["name"] }
      public var symbol: String { __data["symbol"] }
      public var image_uri: String? { __data["image_uri"] }
      public var supply: TubAPI.Numeric? { __data["supply"] }
      public var decimals: TubAPI.Numeric { __data["decimals"] }
      public var description: String { __data["description"] }
      public var external_url: String? { __data["external_url"] }
      public var is_pump_token: Bool { __data["is_pump_token"] }
    }
  }
}
