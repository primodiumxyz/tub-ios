// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetFilteredTokensQuery: GraphQLQuery {
  public static let operationName: String = "GetFilteredTokens"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetFilteredTokens($interval: interval!) { formatted_tokens_interval( args: { interval: $interval } where: { is_pump_token: { _eq: true } } order_by: { trades: desc } ) { __typename token_id mint name symbol description uri supply decimals mint_burnt freeze_burnt is_pump_token increase_pct trades volume latest_price created_at } }"#
    ))

  public var interval: Interval

  public init(interval: Interval) {
    self.interval = interval
  }

  public var __variables: Variables? { ["interval": interval] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("formatted_tokens_interval", [Formatted_tokens_interval].self, arguments: [
        "args": ["interval": .variable("interval")],
        "where": ["is_pump_token": ["_eq": true]],
        "order_by": ["trades": "desc"]
      ]),
    ] }

    public var formatted_tokens_interval: [Formatted_tokens_interval] { __data["formatted_tokens_interval"] }

    /// Formatted_tokens_interval
    ///
    /// Parent Type: `Formatted_tokens`
    public struct Formatted_tokens_interval: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Formatted_tokens }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token_id", TubAPI.Uuid?.self),
        .field("mint", String?.self),
        .field("name", String?.self),
        .field("symbol", String?.self),
        .field("description", String?.self),
        .field("uri", String?.self),
        .field("supply", TubAPI.Numeric?.self),
        .field("decimals", Int?.self),
        .field("mint_burnt", Bool?.self),
        .field("freeze_burnt", Bool?.self),
        .field("is_pump_token", Bool?.self),
        .field("increase_pct", TubAPI.Float8?.self),
        .field("trades", TubAPI.Bigint?.self),
        .field("volume", TubAPI.Numeric?.self),
        .field("latest_price", TubAPI.Numeric?.self),
        .field("created_at", TubAPI.Timestamptz?.self),
      ] }

      public var token_id: TubAPI.Uuid? { __data["token_id"] }
      public var mint: String? { __data["mint"] }
      public var name: String? { __data["name"] }
      public var symbol: String? { __data["symbol"] }
      public var description: String? { __data["description"] }
      public var uri: String? { __data["uri"] }
      public var supply: TubAPI.Numeric? { __data["supply"] }
      public var decimals: Int? { __data["decimals"] }
      public var mint_burnt: Bool? { __data["mint_burnt"] }
      public var freeze_burnt: Bool? { __data["freeze_burnt"] }
      public var is_pump_token: Bool? { __data["is_pump_token"] }
      public var increase_pct: TubAPI.Float8? { __data["increase_pct"] }
      public var trades: TubAPI.Bigint? { __data["trades"] }
      public var volume: TubAPI.Numeric? { __data["volume"] }
      public var latest_price: TubAPI.Numeric? { __data["latest_price"] }
      public var created_at: TubAPI.Timestamptz? { __data["created_at"] }
    }
  }
}
