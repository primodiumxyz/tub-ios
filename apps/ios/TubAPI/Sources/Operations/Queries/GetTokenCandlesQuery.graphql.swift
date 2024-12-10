// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenCandlesQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenCandles"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenCandles($token: String!, $since: timestamptz = "now()", $candle_interval: interval = "1m") { token_trade_history_candles( args: { candle_interval: $candle_interval } where: { token_mint: { _eq: $token }, bucket: { _gte: $since } } ) { __typename bucket open_price_usd close_price_usd high_price_usd low_price_usd volume_usd } }"#
    ))

  public var token: String
  public var since: GraphQLNullable<Timestamptz>
  public var candle_interval: GraphQLNullable<Interval>

  public init(
    token: String,
    since: GraphQLNullable<Timestamptz> = "now()",
    candle_interval: GraphQLNullable<Interval> = "1m"
  ) {
    self.token = token
    self.since = since
    self.candle_interval = candle_interval
  }

  public var __variables: Variables? { [
    "token": token,
    "since": since,
    "candle_interval": candle_interval
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_trade_history_candles", [Token_trade_history_candle].self, arguments: [
        "args": ["candle_interval": .variable("candle_interval")],
        "where": [
          "token_mint": ["_eq": .variable("token")],
          "bucket": ["_gte": .variable("since")]
        ]
      ]),
    ] }

    public var token_trade_history_candles: [Token_trade_history_candle] { __data["token_trade_history_candles"] }

    /// Token_trade_history_candle
    ///
    /// Parent Type: `Trade_history_candle_model`
    public struct Token_trade_history_candle: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Trade_history_candle_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("bucket", TubAPI.Timestamptz.self),
        .field("open_price_usd", TubAPI.Numeric.self),
        .field("close_price_usd", TubAPI.Numeric.self),
        .field("high_price_usd", TubAPI.Numeric.self),
        .field("low_price_usd", TubAPI.Numeric.self),
        .field("volume_usd", TubAPI.Numeric.self),
      ] }

      public var bucket: TubAPI.Timestamptz { __data["bucket"] }
      public var open_price_usd: TubAPI.Numeric { __data["open_price_usd"] }
      public var close_price_usd: TubAPI.Numeric { __data["close_price_usd"] }
      public var high_price_usd: TubAPI.Numeric { __data["high_price_usd"] }
      public var low_price_usd: TubAPI.Numeric { __data["low_price_usd"] }
      public var volume_usd: TubAPI.Numeric { __data["volume_usd"] }
    }
  }
}
