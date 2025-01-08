// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubTokenCandlesSinceSubscription: GraphQLSubscription {
  public static let operationName: String = "SubTokenCandlesSince"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubTokenCandlesSince($token: String!, $since: timestamptz = "now()") { token_candles_history_1min(args: { token_mint: $token, start: $since }) { __typename bucket open_price_usd close_price_usd high_price_usd low_price_usd volume_usd } }"#
    ))

  public var token: String
  public var since: GraphQLNullable<Timestamptz>

  public init(
    token: String,
    since: GraphQLNullable<Timestamptz> = "now()"
  ) {
    self.token = token
    self.since = since
  }

  public var __variables: Variables? { [
    "token": token,
    "since": since
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_candles_history_1min", [Token_candles_history_1min].self, arguments: ["args": [
        "token_mint": .variable("token"),
        "start": .variable("since")
      ]]),
    ] }

    public var token_candles_history_1min: [Token_candles_history_1min] { __data["token_candles_history_1min"] }

    /// Token_candles_history_1min
    ///
    /// Parent Type: `Candles_history_model`
    public struct Token_candles_history_1min: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Candles_history_model }
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
