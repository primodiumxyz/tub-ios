// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetBulkTokenLiveDataQuery: GraphQLQuery {
  public static let operationName: String = "GetBulkTokenLiveData"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetBulkTokenLiveData($tokens: [String!]!) { token_rolling_stats_30min(where: { mint: { _in: $tokens } }) { __typename mint latest_price_usd volume_usd_30m trades_30m price_change_pct_30m volume_usd_1m trades_1m price_change_pct_1m supply } }"#
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
        .field("latest_price_usd", TubAPI.Numeric.self),
        .field("volume_usd_30m", TubAPI.Numeric.self),
        .field("trades_30m", TubAPI.Numeric.self),
        .field("price_change_pct_30m", TubAPI.Numeric.self),
        .field("volume_usd_1m", TubAPI.Numeric.self),
        .field("trades_1m", TubAPI.Numeric.self),
        .field("price_change_pct_1m", TubAPI.Numeric.self),
        .field("supply", TubAPI.Numeric?.self),
      ] }

      public var mint: String { __data["mint"] }
      public var latest_price_usd: TubAPI.Numeric { __data["latest_price_usd"] }
      public var volume_usd_30m: TubAPI.Numeric { __data["volume_usd_30m"] }
      public var trades_30m: TubAPI.Numeric { __data["trades_30m"] }
      public var price_change_pct_30m: TubAPI.Numeric { __data["price_change_pct_30m"] }
      public var volume_usd_1m: TubAPI.Numeric { __data["volume_usd_1m"] }
      public var trades_1m: TubAPI.Numeric { __data["trades_1m"] }
      public var price_change_pct_1m: TubAPI.Numeric { __data["price_change_pct_1m"] }
      public var supply: TubAPI.Numeric? { __data["supply"] }
    }
  }
}
