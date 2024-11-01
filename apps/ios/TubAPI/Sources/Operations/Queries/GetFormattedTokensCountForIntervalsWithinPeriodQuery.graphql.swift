// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetFormattedTokensCountForIntervalsWithinPeriodQuery: GraphQLQuery {
  public static let operationName: String = "GetFormattedTokensCountForIntervalsWithinPeriodQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetFormattedTokensCountForIntervalsWithinPeriodQuery($from: timestamptz!, $to: timestamptz!, $interval: interval!, $increasePct: float8!, $minTrades: bigint!) { get_formatted_tokens_intervals_within_period_aggregate( args: { start: $from end: $to interval: $interval trades: $minTrades increase_pct: $increasePct } ) { __typename interval_start token_count } }"#
    ))

  public var from: Timestamptz
  public var to: Timestamptz
  public var interval: Interval
  public var increasePct: Float8
  public var minTrades: Bigint

  public init(
    from: Timestamptz,
    to: Timestamptz,
    interval: Interval,
    increasePct: Float8,
    minTrades: Bigint
  ) {
    self.from = from
    self.to = to
    self.interval = interval
    self.increasePct = increasePct
    self.minTrades = minTrades
  }

  public var __variables: Variables? { [
    "from": from,
    "to": to,
    "interval": interval,
    "increasePct": increasePct,
    "minTrades": minTrades
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("get_formatted_tokens_intervals_within_period_aggregate", [Get_formatted_tokens_intervals_within_period_aggregate].self, arguments: ["args": [
        "start": .variable("from"),
        "end": .variable("to"),
        "interval": .variable("interval"),
        "trades": .variable("minTrades"),
        "increase_pct": .variable("increasePct")
      ]]),
    ] }

    public var get_formatted_tokens_intervals_within_period_aggregate: [Get_formatted_tokens_intervals_within_period_aggregate] { __data["get_formatted_tokens_intervals_within_period_aggregate"] }

    /// Get_formatted_tokens_intervals_within_period_aggregate
    ///
    /// Parent Type: `Get_formatted_tokens_intervals_within_period_aggregate`
    public struct Get_formatted_tokens_intervals_within_period_aggregate: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Get_formatted_tokens_intervals_within_period_aggregate }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("interval_start", TubAPI.Timestamptz.self),
        .field("token_count", TubAPI.Bigint.self),
      ] }

      public var interval_start: TubAPI.Timestamptz { __data["interval_start"] }
      public var token_count: TubAPI.Bigint { __data["token_count"] }
    }
  }
}
