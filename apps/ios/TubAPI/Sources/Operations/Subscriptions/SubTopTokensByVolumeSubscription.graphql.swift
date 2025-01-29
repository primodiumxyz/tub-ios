// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubTopTokensByVolumeSubscription: GraphQLSubscription {
  public static let operationName: String = "SubTopTokensByVolume"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubTopTokensByVolume($minRecentTrades: numeric = 0, $minRecentVolume: numeric = 0) { token_rolling_stats_30min( where: { is_pump_token: { _eq: true } trades_1m: { _gte: $minRecentTrades } volume_usd_1m: { _gte: $minRecentVolume } } order_by: { volume_usd_30m: desc } limit: 50 ) { __typename mint } }"#
    ))

  public var minRecentTrades: GraphQLNullable<Numeric>
  public var minRecentVolume: GraphQLNullable<Numeric>

  public init(
    minRecentTrades: GraphQLNullable<Numeric> = 0,
    minRecentVolume: GraphQLNullable<Numeric> = 0
  ) {
    self.minRecentTrades = minRecentTrades
    self.minRecentVolume = minRecentVolume
  }

  public var __variables: Variables? { [
    "minRecentTrades": minRecentTrades,
    "minRecentVolume": minRecentVolume
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_rolling_stats_30min", [Token_rolling_stats_30min].self, arguments: [
        "where": [
          "is_pump_token": ["_eq": true],
          "trades_1m": ["_gte": .variable("minRecentTrades")],
          "volume_usd_1m": ["_gte": .variable("minRecentVolume")]
        ],
        "order_by": ["volume_usd_30m": "desc"],
        "limit": 50
      ]),
    ] }

    public var token_rolling_stats_30min: [Token_rolling_stats_30min] { __data["token_rolling_stats_30min"] }

    /// Token_rolling_stats_30min
    ///
    /// Parent Type: `Token_rolling_stats_30min_model`
    public struct Token_rolling_stats_30min: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_rolling_stats_30min_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("mint", String.self),
      ] }

      public var mint: String { __data["mint"] }
    }
  }
}
