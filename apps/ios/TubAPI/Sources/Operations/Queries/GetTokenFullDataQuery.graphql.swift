// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenFullDataQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenFullData"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenFullData($token: String!) { token_rolling_stats_30min(where: { mint: { _eq: $token } }) { __typename mint name symbol description image_uri external_url decimals supply latest_price_usd volume_usd_30m trades_30m price_change_pct_30m volume_usd_1m trades_1m price_change_pct_1m } }"#
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
        .field("description", String.self),
        .field("image_uri", String?.self),
        .field("external_url", String?.self),
        .field("decimals", TubAPI.Numeric.self),
        .field("supply", TubAPI.Numeric?.self),
        .field("latest_price_usd", TubAPI.Numeric.self),
        .field("volume_usd_30m", TubAPI.Numeric.self),
        .field("trades_30m", TubAPI.Numeric.self),
        .field("price_change_pct_30m", TubAPI.Numeric.self),
        .field("volume_usd_1m", TubAPI.Numeric.self),
        .field("trades_1m", TubAPI.Numeric.self),
        .field("price_change_pct_1m", TubAPI.Numeric.self),
      ] }

      public var mint: String { __data["mint"] }
      public var name: String { __data["name"] }
      public var symbol: String { __data["symbol"] }
      public var description: String { __data["description"] }
      public var image_uri: String? { __data["image_uri"] }
      public var external_url: String? { __data["external_url"] }
      public var decimals: TubAPI.Numeric { __data["decimals"] }
      public var supply: TubAPI.Numeric? { __data["supply"] }
      public var latest_price_usd: TubAPI.Numeric { __data["latest_price_usd"] }
      public var volume_usd_30m: TubAPI.Numeric { __data["volume_usd_30m"] }
      public var trades_30m: TubAPI.Numeric { __data["trades_30m"] }
      public var price_change_pct_30m: TubAPI.Numeric { __data["price_change_pct_30m"] }
      public var volume_usd_1m: TubAPI.Numeric { __data["volume_usd_1m"] }
      public var trades_1m: TubAPI.Numeric { __data["trades_1m"] }
      public var price_change_pct_1m: TubAPI.Numeric { __data["price_change_pct_1m"] }
    }
  }
}
