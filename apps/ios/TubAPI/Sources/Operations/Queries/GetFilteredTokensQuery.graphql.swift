// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetFilteredTokensQuery: GraphQLQuery {
  public static let operationName: String = "GetFilteredTokens"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetFilteredTokens($since: timestamptz!, $minTrades: bigint!, $minIncreasePct: float8!) { get_formatted_tokens_since( args: { since: $since } where: { trades: { _gte: $minTrades }, increase_pct: { _gte: $minIncreasePct } } ) { __typename token_id mint decimals name symbol platform latest_price increase_pct trades created_at } }"#
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

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("get_formatted_tokens_since", [Get_formatted_tokens_since].self, arguments: [
        "args": ["since": .variable("since")],
        "where": [
          "trades": ["_gte": .variable("minTrades")],
          "increase_pct": ["_gte": .variable("minIncreasePct")]
        ]
      ]),
    ] }

    public var get_formatted_tokens_since: [Get_formatted_tokens_since] { __data["get_formatted_tokens_since"] }

    /// Get_formatted_tokens_since
    ///
    /// Parent Type: `GetFormattedTokensResult`
    public struct Get_formatted_tokens_since: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.GetFormattedTokensResult }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token_id", TubAPI.Uuid.self),
        .field("mint", String.self),
        .field("decimals", Int.self),
        .field("name", String.self),
        .field("symbol", String.self),
        .field("platform", String.self),
        .field("latest_price", TubAPI.Numeric.self),
        .field("increase_pct", TubAPI.Float8.self),
        .field("trades", TubAPI.Bigint.self),
        .field("created_at", TubAPI.Timestamptz.self),
      ] }

      public var token_id: TubAPI.Uuid { __data["token_id"] }
      public var mint: String { __data["mint"] }
      public var decimals: Int { __data["decimals"] }
      public var name: String { __data["name"] }
      public var symbol: String { __data["symbol"] }
      public var platform: String { __data["platform"] }
      public var latest_price: TubAPI.Numeric { __data["latest_price"] }
      public var increase_pct: TubAPI.Float8 { __data["increase_pct"] }
      public var trades: TubAPI.Bigint { __data["trades"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
    }
  }
}
