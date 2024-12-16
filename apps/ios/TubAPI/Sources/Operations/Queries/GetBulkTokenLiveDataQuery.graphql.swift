// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetBulkTokenLiveDataQuery: GraphQLQuery {
  public static let operationName: String = "GetBulkTokenLiveData"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetBulkTokenLiveData($tokens: [String!]!) { token_stats_interval_comp( where: { token_mint: { _in: $tokens } } args: { interval: "30m", recent_interval: "2m" } ) { __typename token_mint latest_price_usd total_volume_usd total_trades price_change_pct recent_volume_usd recent_trades recent_price_change_pct token_metadata_supply } }"#
    ))

  public var tokens: [String]

  public init(tokens: [String]) {
    self.tokens = tokens
  }

  public var __variables: Variables? { ["tokens": tokens] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_stats_interval_comp", [Token_stats_interval_comp].self, arguments: [
        "where": ["token_mint": ["_in": .variable("tokens")]],
        "args": [
          "interval": "30m",
          "recent_interval": "2m"
        ]
      ]),
    ] }

    public var token_stats_interval_comp: [Token_stats_interval_comp] { __data["token_stats_interval_comp"] }

    /// Token_stats_interval_comp
    ///
    /// Parent Type: `Token_stats_model`
    public struct Token_stats_interval_comp: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_stats_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token_mint", String.self),
        .field("latest_price_usd", TubAPI.Numeric.self),
        .field("total_volume_usd", TubAPI.Numeric.self),
        .field("total_trades", TubAPI.Numeric.self),
        .field("price_change_pct", TubAPI.Numeric.self),
        .field("recent_volume_usd", TubAPI.Numeric.self),
        .field("recent_trades", TubAPI.Numeric.self),
        .field("recent_price_change_pct", TubAPI.Numeric.self),
        .field("token_metadata_supply", TubAPI.Numeric?.self),
      ] }

      public var token_mint: String { __data["token_mint"] }
      public var latest_price_usd: TubAPI.Numeric { __data["latest_price_usd"] }
      public var total_volume_usd: TubAPI.Numeric { __data["total_volume_usd"] }
      public var total_trades: TubAPI.Numeric { __data["total_trades"] }
      public var price_change_pct: TubAPI.Numeric { __data["price_change_pct"] }
      public var recent_volume_usd: TubAPI.Numeric { __data["recent_volume_usd"] }
      public var recent_trades: TubAPI.Numeric { __data["recent_trades"] }
      public var recent_price_change_pct: TubAPI.Numeric { __data["recent_price_change_pct"] }
      public var token_metadata_supply: TubAPI.Numeric? { __data["token_metadata_supply"] }
    }
  }
}
