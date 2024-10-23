// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenPriceHistoryIgnoreIntervalQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenPriceHistoryIgnoreInterval"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenPriceHistoryIgnoreInterval($token: uuid, $start: timestamptz = "now()", $interval: interval!) { token_price_history_offset( args: { offset: $interval } where: { created_at_offset: { _lte: $start }, token: { _eq: $token } } order_by: { created_at: desc } ) { __typename created_at price } }"#
    ))

  public var token: GraphQLNullable<Uuid>
  public var start: GraphQLNullable<Timestamptz>
  public var interval: Interval

  public init(
    token: GraphQLNullable<Uuid>,
    start: GraphQLNullable<Timestamptz> = "now()",
    interval: Interval
  ) {
    self.token = token
    self.start = start
    self.interval = interval
  }

  public var __variables: Variables? { [
    "token": token,
    "start": start,
    "interval": interval
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_price_history_offset", [Token_price_history_offset].self, arguments: [
        "args": ["offset": .variable("interval")],
        "where": [
          "created_at_offset": ["_lte": .variable("start")],
          "token": ["_eq": .variable("token")]
        ],
        "order_by": ["created_at": "desc"]
      ]),
    ] }

    public var token_price_history_offset: [Token_price_history_offset] { __data["token_price_history_offset"] }

    /// Token_price_history_offset
    ///
    /// Parent Type: `Token_price_history_offset`
    public struct Token_price_history_offset: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_price_history_offset }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("created_at", TubAPI.Timestamptz.self),
        .field("price", TubAPI.Numeric.self),
      ] }

      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      public var price: TubAPI.Numeric { __data["price"] }
    }
  }
}
