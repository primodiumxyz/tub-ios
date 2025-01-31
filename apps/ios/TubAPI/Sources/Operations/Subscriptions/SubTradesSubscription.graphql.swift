// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubTradesSubscription: GraphQLSubscription {
  public static let operationName: String = "SubTrades"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubTrades($limit: Int = 1000) { transactions(order_by: { created_at: desc }, limit: $limit) { __typename id created_at user_wallet token_mint token_amount token_price_usd token_value_usd token_decimals success error_details } }"#
    ))

  public var limit: GraphQLNullable<Int>

  public init(limit: GraphQLNullable<Int> = 1000) {
    self.limit = limit
  }

  public var __variables: Variables? { ["limit": limit] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("transactions", [Transaction].self, arguments: [
        "order_by": ["created_at": "desc"],
        "limit": .variable("limit")
      ]),
    ] }

    public var transactions: [Transaction] { __data["transactions"] }

    /// Transaction
    ///
    /// Parent Type: `Transaction_model`
    public struct Transaction: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Transaction_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
        .field("created_at", TubAPI.Timestamptz.self),
        .field("user_wallet", String.self),
        .field("token_mint", String.self),
        .field("token_amount", TubAPI.Numeric.self),
        .field("token_price_usd", TubAPI.Numeric.self),
        .field("token_value_usd", TubAPI.Numeric.self),
        .field("token_decimals", Int.self),
        .field("success", Bool.self),
        .field("error_details", String?.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      public var user_wallet: String { __data["user_wallet"] }
      public var token_mint: String { __data["token_mint"] }
      public var token_amount: TubAPI.Numeric { __data["token_amount"] }
      public var token_price_usd: TubAPI.Numeric { __data["token_price_usd"] }
      public var token_value_usd: TubAPI.Numeric { __data["token_value_usd"] }
      public var token_decimals: Int { __data["token_decimals"] }
      public var success: Bool { __data["success"] }
      public var error_details: String? { __data["error_details"] }
    }
  }
}
