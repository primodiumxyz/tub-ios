// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetWalletTransactionsQuery: GraphQLQuery {
  public static let operationName: String = "GetWalletTransactions"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetWalletTransactions($wallet: String!) { transactions( where: { user_wallet: { _eq: $wallet }, success: { _eq: true } } order_by: { created_at: desc } ) { __typename id created_at token_mint token_amount token_price_usd } }"#
    ))

  public var wallet: String

  public init(wallet: String) {
    self.wallet = wallet
  }

  public var __variables: Variables? { ["wallet": wallet] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("transactions", [Transaction].self, arguments: [
        "where": [
          "user_wallet": ["_eq": .variable("wallet")],
          "success": ["_eq": true]
        ],
        "order_by": ["created_at": "desc"]
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
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      public var token_mint: String { __data["token_mint"] }
      public var token_amount: TubAPI.Numeric { __data["token_amount"] }
      public var token_price_usd: TubAPI.Numeric { __data["token_price_usd"] }
    }
  }
}
