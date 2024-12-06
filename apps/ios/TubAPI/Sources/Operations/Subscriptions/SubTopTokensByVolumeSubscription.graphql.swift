// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubTopTokensByVolumeSubscription: GraphQLSubscription {
  public static let operationName: String = "SubTopTokensByVolume"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubTopTokensByVolume($interval: interval = "30m", $recentInterval: interval = "20s", $minRecentTrades: numeric = 0, $minRecentVolume: numeric = 0) { token_stats_interval_comp( args: { interval: $interval, recent_interval: $recentInterval } where: { token_metadata_is_pump_token: { _eq: true } recent_trades: { _gte: $minRecentTrades } recent_volume_usd: { _gte: $minRecentVolume } } order_by: { total_volume_usd: desc } limit: 50 ) { __typename token_mint total_volume_usd total_trades price_change_pct recent_volume_usd recent_trades recent_price_change_pct token_metadata_name token_metadata_symbol token_metadata_description token_metadata_image_uri token_metadata_external_url token_metadata_supply } }"#
    ))

  public var interval: GraphQLNullable<Interval>
  public var recentInterval: GraphQLNullable<Interval>
  public var minRecentTrades: GraphQLNullable<Numeric>
  public var minRecentVolume: GraphQLNullable<Numeric>

  public init(
    interval: GraphQLNullable<Interval> = "30m",
    recentInterval: GraphQLNullable<Interval> = "20s",
    minRecentTrades: GraphQLNullable<Numeric> = 0,
    minRecentVolume: GraphQLNullable<Numeric> = 0
  ) {
    self.interval = interval
    self.recentInterval = recentInterval
    self.minRecentTrades = minRecentTrades
    self.minRecentVolume = minRecentVolume
  }

  public var __variables: Variables? { [
    "interval": interval,
    "recentInterval": recentInterval,
    "minRecentTrades": minRecentTrades,
    "minRecentVolume": minRecentVolume
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_stats_interval_comp", [Token_stats_interval_comp].self, arguments: [
        "args": [
          "interval": .variable("interval"),
          "recent_interval": .variable("recentInterval")
        ],
        "where": [
          "token_metadata_is_pump_token": ["_eq": true],
          "recent_trades": ["_gte": .variable("minRecentTrades")],
          "recent_volume_usd": ["_gte": .variable("minRecentVolume")]
        ],
        "order_by": ["total_volume_usd": "desc"],
        "limit": 50
      ]),
    ] }

    public var token_stats_interval_comp: [Token_stats_interval_comp] { __data["token_stats_interval_comp"] }

    /// Token_stats_interval_comp
    ///
    /// Parent Type: `Token_stats_model`
    public struct Token_stats_interval_comp: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_stats_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token_mint", String.self),
        .field("total_volume_usd", TubAPI.Numeric.self),
        .field("total_trades", TubAPI.Numeric.self),
        .field("price_change_pct", TubAPI.Numeric.self),
        .field("recent_volume_usd", TubAPI.Numeric.self),
        .field("recent_trades", TubAPI.Numeric.self),
        .field("recent_price_change_pct", TubAPI.Numeric.self),
        .field("token_metadata_name", String.self),
        .field("token_metadata_symbol", String.self),
        .field("token_metadata_description", String.self),
        .field("token_metadata_image_uri", String?.self),
        .field("token_metadata_external_url", String?.self),
        .field("token_metadata_supply", TubAPI.Numeric?.self),
      ] }

      public var token_mint: String { __data["token_mint"] }
      public var total_volume_usd: TubAPI.Numeric { __data["total_volume_usd"] }
      public var total_trades: TubAPI.Numeric { __data["total_trades"] }
      public var price_change_pct: TubAPI.Numeric { __data["price_change_pct"] }
      public var recent_volume_usd: TubAPI.Numeric { __data["recent_volume_usd"] }
      public var recent_trades: TubAPI.Numeric { __data["recent_trades"] }
      public var recent_price_change_pct: TubAPI.Numeric { __data["recent_price_change_pct"] }
      public var token_metadata_name: String { __data["token_metadata_name"] }
      public var token_metadata_symbol: String { __data["token_metadata_symbol"] }
      public var token_metadata_description: String { __data["token_metadata_description"] }
      public var token_metadata_image_uri: String? { __data["token_metadata_image_uri"] }
      public var token_metadata_external_url: String? { __data["token_metadata_external_url"] }
      public var token_metadata_supply: TubAPI.Numeric? { __data["token_metadata_supply"] }
    }
  }
}
