// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetSwapsInPeriodQuery: GraphQLQuery {
  public static let operationName: String = "GetSwapsInPeriod"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetSwapsInPeriod($from: timestamptz!, $to: timestamptz!) { swaps_total: token_price_history_aggregate( where: { created_at: { _gte: $from, _lte: $to } } ) { __typename aggregate { __typename count } } swaps_hourly: hourly_swaps(where: { hour: { _gte: $from, _lte: $to } }) { __typename hour count } }"#
    ))

  public var from: Timestamptz
  public var to: Timestamptz

  public init(
    from: Timestamptz,
    to: Timestamptz
  ) {
    self.from = from
    self.to = to
  }

  public var __variables: Variables? { [
    "from": from,
    "to": to
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_price_history_aggregate", alias: "swaps_total", Swaps_total.self, arguments: ["where": ["created_at": [
        "_gte": .variable("from"),
        "_lte": .variable("to")
      ]]]),
      .field("hourly_swaps", alias: "swaps_hourly", [Swaps_hourly].self, arguments: ["where": ["hour": [
        "_gte": .variable("from"),
        "_lte": .variable("to")
      ]]]),
    ] }

    /// fetch aggregated fields from the table: "token_price_history"
    public var swaps_total: Swaps_total { __data["swaps_total"] }
    /// fetch data from the table: "hourly_swaps"
    public var swaps_hourly: [Swaps_hourly] { __data["swaps_hourly"] }

    /// Swaps_total
    ///
    /// Parent Type: `Token_price_history_aggregate`
    public struct Swaps_total: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_price_history_aggregate }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("aggregate", Aggregate?.self),
      ] }

      public var aggregate: Aggregate? { __data["aggregate"] }

      /// Swaps_total.Aggregate
      ///
      /// Parent Type: `Token_price_history_aggregate_fields`
      public struct Aggregate: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_price_history_aggregate_fields }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("count", Int.self),
        ] }

        public var count: Int { __data["count"] }
      }
    }

    /// Swaps_hourly
    ///
    /// Parent Type: `Hourly_swaps`
    public struct Swaps_hourly: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Hourly_swaps }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("hour", TubAPI.Timestamptz?.self),
        .field("count", TubAPI.Bigint?.self),
      ] }

      public var hour: TubAPI.Timestamptz? { __data["hour"] }
      public var count: TubAPI.Bigint? { __data["count"] }
    }
  }
}
