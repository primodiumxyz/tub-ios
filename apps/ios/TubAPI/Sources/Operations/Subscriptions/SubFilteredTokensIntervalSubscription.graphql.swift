// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubFilteredTokensIntervalSubscription: GraphQLSubscription {
  public static let operationName: String = "SubFilteredTokensInterval"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubFilteredTokensInterval($interval: interval = "30s", $minTrades: bigint!, $minIncreasePct: float8!, $mintFilter: String = "%") { get_formatted_tokens_interval( args: { interval: $interval } where: { trades: { _gte: $minTrades } increase_pct: { _gte: $minIncreasePct } mint: { _ilike: $mintFilter } } ) { __typename token_id mint decimals name platform symbol latest_price increase_pct trades created_at } }"#
    ))

  public var interval: GraphQLNullable<Interval>
  public var minTrades: Bigint
  public var minIncreasePct: Float8
  public var mintFilter: GraphQLNullable<String>

  public init(
    interval: GraphQLNullable<Interval> = "30s",
    minTrades: Bigint,
    minIncreasePct: Float8,
    mintFilter: GraphQLNullable<String> = "%"
  ) {
    self.interval = interval
    self.minTrades = minTrades
    self.minIncreasePct = minIncreasePct
    self.mintFilter = mintFilter
  }

  public var __variables: Variables? { [
    "interval": interval,
    "minTrades": minTrades,
    "minIncreasePct": minIncreasePct,
    "mintFilter": mintFilter
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("get_formatted_tokens_interval", [Get_formatted_tokens_interval].self, arguments: [
        "args": ["interval": .variable("interval")],
        "where": [
          "trades": ["_gte": .variable("minTrades")],
          "increase_pct": ["_gte": .variable("minIncreasePct")],
          "mint": ["_ilike": .variable("mintFilter")]
        ]
      ]),
    ] }

    public var get_formatted_tokens_interval: [Get_formatted_tokens_interval] { __data["get_formatted_tokens_interval"] }

    /// Get_formatted_tokens_interval
    ///
    /// Parent Type: `GetFormattedTokensResult`
    public struct Get_formatted_tokens_interval: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.GetFormattedTokensResult }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token_id", TubAPI.Uuid.self),
        .field("mint", String.self),
        .field("decimals", Int?.self),
        .field("name", String.self),
        .field("platform", String.self),
        .field("symbol", String.self),
        .field("latest_price", TubAPI.Numeric.self),
        .field("increase_pct", TubAPI.Float8.self),
        .field("trades", TubAPI.Bigint.self),
        .field("created_at", TubAPI.Timestamptz.self),
      ] }

      public var token_id: TubAPI.Uuid { __data["token_id"] }
      public var mint: String { __data["mint"] }
      public var decimals: Int? { __data["decimals"] }
      public var name: String { __data["name"] }
      public var platform: String { __data["platform"] }
      public var symbol: String { __data["symbol"] }
      public var latest_price: TubAPI.Numeric { __data["latest_price"] }
      public var increase_pct: TubAPI.Float8 { __data["increase_pct"] }
      public var trades: TubAPI.Bigint { __data["trades"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
    }
  }
}
