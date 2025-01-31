// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetLatestTokenPurchaseQuery: GraphQLQuery {
  public static let operationName: String = "GetLatestTokenPurchase"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetLatestTokenPurchase($wallet: String!, $mint: String!) { transactions( where: { user_wallet: { _eq: $wallet } token_mint: { _eq: $mint } success: { _eq: true } token_amount: { _gt: 0 } } order_by: { created_at: desc } limit: 1 ) { __typename id created_at token_mint token_amount token_price_usd token_value_usd } }"#
    ))

  public var wallet: String
  public var mint: String

  public init(
    wallet: String,
    mint: String
  ) {
    self.wallet = wallet
    self.mint = mint
  }

  public var __variables: Variables? { [
    "wallet": wallet,
    "mint": mint
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("transactions", [Transaction].self, arguments: [
        "where": [
          "user_wallet": ["_eq": .variable("wallet")],
          "token_mint": ["_eq": .variable("mint")],
          "success": ["_eq": true],
          "token_amount": ["_gt": 0]
        ],
        "order_by": ["created_at": "desc"],
        "limit": 1
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
        .field("token_mint", String.self),
        .field("token_amount", TubAPI.Numeric.self),
        .field("token_price_usd", TubAPI.Numeric.self),
        .field("token_value_usd", TubAPI.Numeric.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      public var token_mint: String { __data["token_mint"] }
      public var token_amount: TubAPI.Numeric { __data["token_amount"] }
      public var token_price_usd: TubAPI.Numeric { __data["token_price_usd"] }
      public var token_value_usd: TubAPI.Numeric { __data["token_value_usd"] }
    }
  }
}
