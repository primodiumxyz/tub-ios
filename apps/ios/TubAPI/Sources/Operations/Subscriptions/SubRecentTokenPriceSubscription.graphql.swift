// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubRecentTokenPriceSubscription: GraphQLSubscription {
  public static let operationName: String = "SubRecentTokenPrice"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubRecentTokenPrice($token: String!) { api_trade_history( where: { token_mint: { _eq: $token } } order_by: { created_at: desc } limit: 1 ) { __typename token_price_usd created_at } }"#
    ))

  public var token: String

  public init(token: String) {
    self.token = token
  }

  public var __variables: Variables? { ["token": token] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("api_trade_history", [Api_trade_history].self, arguments: [
        "where": ["token_mint": ["_eq": .variable("token")]],
        "order_by": ["created_at": "desc"],
        "limit": 1
      ]),
    ] }

    /// fetch data from the table: "api.trade_history"
    public var api_trade_history: [Api_trade_history] { __data["api_trade_history"] }

    /// Api_trade_history
    ///
    /// Parent Type: `Api_trade_history`
    public struct Api_trade_history: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Api_trade_history }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token_price_usd", TubAPI.Numeric.self),
        .field("created_at", TubAPI.Timestamptz.self),
      ] }

      public var token_price_usd: TubAPI.Numeric { __data["token_price_usd"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
    }
  }
}
