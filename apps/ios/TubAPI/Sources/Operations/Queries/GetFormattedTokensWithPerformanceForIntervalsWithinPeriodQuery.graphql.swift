// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery: GraphQLQuery {
  public static let operationName: String = "GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery($from: timestamptz!, $to: timestamptz!, $interval: interval!, $afterIntervals: String!, $minTrades: bigint = 0, $minVolume: numeric = 0, $mintBurnt: Boolean = false, $freezeBurnt: Boolean = false) { formatted_tokens_with_performance_intervals_within_period( args: { start: $from end: $to interval: $interval after_intervals: $afterIntervals } where: { trades: { _gte: $minTrades } volume: { _gte: $minVolume } _and: [ { _or: [{ _not: { mint_burnt: { _eq: $mintBurnt } } }, { mint_burnt: { _eq: true } }] } { _or: [ { _not: { freeze_burnt: { _eq: $freezeBurnt } } } { freeze_burnt: { _eq: true } } ] } ] } order_by: { interval_start: asc } ) { __typename token_id mint name symbol description uri supply decimals mint_burnt freeze_burnt is_pump_token increase_pct trades volume latest_price created_at increase_pct_after trades_after volume_after interval_start } }"#
    ))

  public var from: Timestamptz
  public var to: Timestamptz
  public var interval: Interval
  public var afterIntervals: String
  public var minTrades: GraphQLNullable<Bigint>
  public var minVolume: GraphQLNullable<Numeric>
  public var mintBurnt: GraphQLNullable<Bool>
  public var freezeBurnt: GraphQLNullable<Bool>

  public init(
    from: Timestamptz,
    to: Timestamptz,
    interval: Interval,
    afterIntervals: String,
    minTrades: GraphQLNullable<Bigint> = 0,
    minVolume: GraphQLNullable<Numeric> = 0,
    mintBurnt: GraphQLNullable<Bool> = false,
    freezeBurnt: GraphQLNullable<Bool> = false
  ) {
    self.from = from
    self.to = to
    self.interval = interval
    self.afterIntervals = afterIntervals
    self.minTrades = minTrades
    self.minVolume = minVolume
    self.mintBurnt = mintBurnt
    self.freezeBurnt = freezeBurnt
  }

  public var __variables: Variables? { [
    "from": from,
    "to": to,
    "interval": interval,
    "afterIntervals": afterIntervals,
    "minTrades": minTrades,
    "minVolume": minVolume,
    "mintBurnt": mintBurnt,
    "freezeBurnt": freezeBurnt
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("formatted_tokens_with_performance_intervals_within_period", [Formatted_tokens_with_performance_intervals_within_period].self, arguments: [
        "args": [
          "start": .variable("from"),
          "end": .variable("to"),
          "interval": .variable("interval"),
          "after_intervals": .variable("afterIntervals")
        ],
        "where": [
          "trades": ["_gte": .variable("minTrades")],
          "volume": ["_gte": .variable("minVolume")],
          "_and": [["_or": [["_not": ["mint_burnt": ["_eq": .variable("mintBurnt")]]], ["mint_burnt": ["_eq": true]]]], ["_or": [["_not": ["freeze_burnt": ["_eq": .variable("freezeBurnt")]]], ["freeze_burnt": ["_eq": true]]]]]
        ],
        "order_by": ["interval_start": "asc"]
      ]),
    ] }

    public var formatted_tokens_with_performance_intervals_within_period: [Formatted_tokens_with_performance_intervals_within_period] { __data["formatted_tokens_with_performance_intervals_within_period"] }

    /// Formatted_tokens_with_performance_intervals_within_period
    ///
    /// Parent Type: `Formatted_tokens_with_performance_model`
    public struct Formatted_tokens_with_performance_intervals_within_period: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Formatted_tokens_with_performance_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token_id", TubAPI.Uuid.self),
        .field("mint", String.self),
        .field("name", String?.self),
        .field("symbol", String?.self),
        .field("description", String?.self),
        .field("uri", String?.self),
        .field("supply", TubAPI.Numeric?.self),
        .field("decimals", Int?.self),
        .field("mint_burnt", Bool?.self),
        .field("freeze_burnt", Bool?.self),
        .field("is_pump_token", Bool?.self),
        .field("increase_pct", TubAPI.Float8.self),
        .field("trades", TubAPI.Bigint.self),
        .field("volume", TubAPI.Numeric.self),
        .field("latest_price", TubAPI.Numeric.self),
        .field("created_at", TubAPI.Timestamptz.self),
        .field("increase_pct_after", String.self),
        .field("trades_after", String.self),
        .field("volume_after", String.self),
        .field("interval_start", TubAPI.Timestamptz.self),
      ] }

      public var token_id: TubAPI.Uuid { __data["token_id"] }
      public var mint: String { __data["mint"] }
      public var name: String? { __data["name"] }
      public var symbol: String? { __data["symbol"] }
      public var description: String? { __data["description"] }
      public var uri: String? { __data["uri"] }
      public var supply: TubAPI.Numeric? { __data["supply"] }
      public var decimals: Int? { __data["decimals"] }
      public var mint_burnt: Bool? { __data["mint_burnt"] }
      public var freeze_burnt: Bool? { __data["freeze_burnt"] }
      public var is_pump_token: Bool? { __data["is_pump_token"] }
      public var increase_pct: TubAPI.Float8 { __data["increase_pct"] }
      public var trades: TubAPI.Bigint { __data["trades"] }
      public var volume: TubAPI.Numeric { __data["volume"] }
      public var latest_price: TubAPI.Numeric { __data["latest_price"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      public var increase_pct_after: String { __data["increase_pct_after"] }
      public var trades_after: String { __data["trades_after"] }
      public var volume_after: String { __data["volume_after"] }
      public var interval_start: TubAPI.Timestamptz { __data["interval_start"] }
    }
  }
}
