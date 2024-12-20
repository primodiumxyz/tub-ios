// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTopTokensByVolumeQuery: GraphQLQuery {
  public static let operationName: String = "GetTopTokensByVolume"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTopTokensByVolume($interval: interval = "30m", $recentInterval: interval = "20s", $minRecentTrades: numeric = 0, $minRecentVolume: numeric = 0) { token_stats_interval_comp( args: { interval: $interval, recent_interval: $recentInterval } where: { token_metadata_is_pump_token: { _eq: true } recent_trades: { _gte: $minRecentTrades } recent_volume_usd: { _gte: $minRecentVolume } } order_by: { total_volume_usd: desc } limit: 50 ) { __typename token_mint } }"#
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

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
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
      ] }

      public var token_mint: String { __data["token_mint"] }
    }
  }
}
