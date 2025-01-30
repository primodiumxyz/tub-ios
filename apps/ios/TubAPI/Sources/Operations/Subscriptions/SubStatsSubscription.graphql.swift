// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubStatsSubscription: GraphQLSubscription {
  public static let operationName: String = "SubStats"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubStats($userWallet: String, $tokenMint: String) { transaction_analytics( args: { user_wallet: $userWallet, token_mint: $tokenMint } ) { __typename total_pnl_usd total_volume_usd trade_count success_rate } }"#
    ))

  public var userWallet: GraphQLNullable<String>
  public var tokenMint: GraphQLNullable<String>

  public init(
    userWallet: GraphQLNullable<String>,
    tokenMint: GraphQLNullable<String>
  ) {
    self.userWallet = userWallet
    self.tokenMint = tokenMint
  }

  public var __variables: Variables? { [
    "userWallet": userWallet,
    "tokenMint": tokenMint
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("transaction_analytics", [Transaction_analytic].self, arguments: ["args": [
        "user_wallet": .variable("userWallet"),
        "token_mint": .variable("tokenMint")
      ]]),
    ] }

    public var transaction_analytics: [Transaction_analytic] { __data["transaction_analytics"] }

    /// Transaction_analytic
    ///
    /// Parent Type: `Transaction_analytics_model`
    public struct Transaction_analytic: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Transaction_analytics_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("total_pnl_usd", TubAPI.Numeric.self),
        .field("total_volume_usd", TubAPI.Numeric.self),
        .field("trade_count", TubAPI.Bigint.self),
        .field("success_rate", TubAPI.Numeric.self),
      ] }

      public var total_pnl_usd: TubAPI.Numeric { __data["total_pnl_usd"] }
      public var total_volume_usd: TubAPI.Numeric { __data["total_volume_usd"] }
      public var trade_count: TubAPI.Bigint { __data["trade_count"] }
      public var success_rate: TubAPI.Numeric { __data["success_rate"] }
    }
  }
}
