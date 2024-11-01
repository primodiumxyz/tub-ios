// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery: GraphQLQuery {
  public static let operationName: String = "GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery($from: timestamptz!, $to: timestamptz!, $interval: interval!, $afterIntervals: String!, $increasePct: float8!, $minTrades: bigint!, $mintFilter: String = "%") { get_formatted_tokens_with_performance_intervals_within_period( args: { start: $from end: $to interval: $interval after_intervals: $afterIntervals } where: { trades: { _gte: $minTrades } increase_pct: { _gte: $increasePct } mint: { _ilike: $mintFilter } } order_by: { interval_start: asc } ) { __typename mint increase_pct trades increase_pct_after trades_after created_at interval_start } }"#
    ))

  public var from: Timestamptz
  public var to: Timestamptz
  public var interval: Interval
  public var afterIntervals: String
  public var increasePct: Float8
  public var minTrades: Bigint
  public var mintFilter: GraphQLNullable<String>

  public init(
    from: Timestamptz,
    to: Timestamptz,
    interval: Interval,
    afterIntervals: String,
    increasePct: Float8,
    minTrades: Bigint,
    mintFilter: GraphQLNullable<String> = "%"
  ) {
    self.from = from
    self.to = to
    self.interval = interval
    self.afterIntervals = afterIntervals
    self.increasePct = increasePct
    self.minTrades = minTrades
    self.mintFilter = mintFilter
  }

  public var __variables: Variables? { [
    "from": from,
    "to": to,
    "interval": interval,
    "afterIntervals": afterIntervals,
    "increasePct": increasePct,
    "minTrades": minTrades,
    "mintFilter": mintFilter
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("get_formatted_tokens_with_performance_intervals_within_period", [Get_formatted_tokens_with_performance_intervals_within_period].self, arguments: [
        "args": [
          "start": .variable("from"),
          "end": .variable("to"),
          "interval": .variable("interval"),
          "after_intervals": .variable("afterIntervals")
        ],
        "where": [
          "trades": ["_gte": .variable("minTrades")],
          "increase_pct": ["_gte": .variable("increasePct")],
          "mint": ["_ilike": .variable("mintFilter")]
        ],
        "order_by": ["interval_start": "asc"]
      ]),
    ] }

    public var get_formatted_tokens_with_performance_intervals_within_period: [Get_formatted_tokens_with_performance_intervals_within_period] { __data["get_formatted_tokens_with_performance_intervals_within_period"] }

    /// Get_formatted_tokens_with_performance_intervals_within_period
    ///
    /// Parent Type: `GetFormattedTokensWithPerformanceResult`
    public struct Get_formatted_tokens_with_performance_intervals_within_period: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.GetFormattedTokensWithPerformanceResult }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("mint", String.self),
        .field("increase_pct", TubAPI.Float8.self),
        .field("trades", TubAPI.Bigint.self),
        .field("increase_pct_after", String.self),
        .field("trades_after", String.self),
        .field("created_at", TubAPI.Timestamptz.self),
        .field("interval_start", TubAPI.Timestamptz.self),
      ] }

      public var mint: String { __data["mint"] }
      public var increase_pct: TubAPI.Float8 { __data["increase_pct"] }
      public var trades: TubAPI.Bigint { __data["trades"] }
      public var increase_pct_after: String { __data["increase_pct_after"] }
      public var trades_after: String { __data["trades_after"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      public var interval_start: TubAPI.Timestamptz { __data["interval_start"] }
    }
  }
}
