// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubFilteredTokensSubscription: GraphQLSubscription {
  public static let operationName: String = "SubFilteredTokens"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubFilteredTokens($since: timestamptz!, $minTrades: bigint!, $minIncreasePct: float8!) { GetFormattedTokens( args: { since: $since } where: { trades: { _gte: $minTrades }, increase_pct: { _gte: $minIncreasePct } } ) { __typename token_id mint name symbol latest_price increase_pct trades created_at } }"#
    ))

  public var since: Timestamptz
  public var minTrades: Bigint
  public var minIncreasePct: Float8

  public init(
    since: Timestamptz,
    minTrades: Bigint,
    minIncreasePct: Float8
  ) {
    self.since = since
    self.minTrades = minTrades
    self.minIncreasePct = minIncreasePct
  }

  public var __variables: Variables? { [
    "since": since,
    "minTrades": minTrades,
    "minIncreasePct": minIncreasePct
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("GetFormattedTokens", [GetFormattedToken].self, arguments: [
        "args": ["since": .variable("since")],
        "where": [
          "trades": ["_gte": .variable("minTrades")],
          "increase_pct": ["_gte": .variable("minIncreasePct")]
        ]
      ]),
    ] }

    public var getFormattedTokens: [GetFormattedToken] { __data["GetFormattedTokens"] }

    /// GetFormattedToken
    ///
    /// Parent Type: `GetFormattedTokensResult`
    public struct GetFormattedToken: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.GetFormattedTokensResult }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token_id", TubAPI.Uuid.self),
        .field("mint", String.self),
        .field("name", String?.self),
        .field("symbol", String?.self),
        .field("latest_price", TubAPI.Numeric.self),
        .field("increase_pct", TubAPI.Float8.self),
        .field("trades", TubAPI.Bigint.self),
        .field("created_at", TubAPI.Timestamptz.self),
      ] }

      public var token_id: TubAPI.Uuid { __data["token_id"] }
      public var mint: String { __data["mint"] }
      public var name: String? { __data["name"] }
      public var symbol: String? { __data["symbol"] }
      public var latest_price: TubAPI.Numeric { __data["latest_price"] }
      public var increase_pct: TubAPI.Float8 { __data["increase_pct"] }
      public var trades: TubAPI.Bigint { __data["trades"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
    }
  }
}
