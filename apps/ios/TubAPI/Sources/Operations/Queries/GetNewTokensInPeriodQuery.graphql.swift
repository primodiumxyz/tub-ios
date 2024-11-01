// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetNewTokensInPeriodQuery: GraphQLQuery {
  public static let operationName: String = "GetNewTokensInPeriod"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetNewTokensInPeriod($from: timestamptz!, $to: timestamptz!) { new_tokens_total: token_aggregate( where: { created_at: { _gte: $from, _lte: $to } } ) { __typename aggregate { __typename count } } new_tokens_hourly: hourly_new_tokens( where: { hour: { _gte: $from, _lte: $to } } ) { __typename hour count } }"#
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
      .field("token_aggregate", alias: "new_tokens_total", New_tokens_total.self, arguments: ["where": ["created_at": [
        "_gte": .variable("from"),
        "_lte": .variable("to")
      ]]]),
      .field("hourly_new_tokens", alias: "new_tokens_hourly", [New_tokens_hourly].self, arguments: ["where": ["hour": [
        "_gte": .variable("from"),
        "_lte": .variable("to")
      ]]]),
    ] }

    /// fetch aggregated fields from the table: "token"
    public var new_tokens_total: New_tokens_total { __data["new_tokens_total"] }
    /// fetch data from the table: "hourly_new_tokens"
    public var new_tokens_hourly: [New_tokens_hourly] { __data["new_tokens_hourly"] }

    /// New_tokens_total
    ///
    /// Parent Type: `Token_aggregate`
    public struct New_tokens_total: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_aggregate }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("aggregate", Aggregate?.self),
      ] }

      public var aggregate: Aggregate? { __data["aggregate"] }

      /// New_tokens_total.Aggregate
      ///
      /// Parent Type: `Token_aggregate_fields`
      public struct Aggregate: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_aggregate_fields }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("count", Int.self),
        ] }

        public var count: Int { __data["count"] }
      }
    }

    /// New_tokens_hourly
    ///
    /// Parent Type: `Hourly_new_tokens`
    public struct New_tokens_hourly: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Hourly_new_tokens }
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
