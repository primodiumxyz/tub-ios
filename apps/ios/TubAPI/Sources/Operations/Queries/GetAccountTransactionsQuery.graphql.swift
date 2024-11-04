// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAccountTransactionsQuery: GraphQLQuery {
  public static let operationName: String = "GetAccountTransactions"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetAccountTransactions($accountId: uuid!) { token_transaction( order_by: { account_transaction_data: { created_at: desc } } where: { account_transaction_data: { account_data: { id: { _eq: $accountId } } } } ) { __typename account_transaction amount id token token_data { __typename id name supply symbol uri } account_transaction_data { __typename created_at } token_price { __typename price created_at } } }"#
    ))

  public var accountId: Uuid

  public init(accountId: Uuid) {
    self.accountId = accountId
  }

  public var __variables: Variables? { ["accountId": accountId] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_transaction", [Token_transaction].self, arguments: [
        "order_by": ["account_transaction_data": ["created_at": "desc"]],
        "where": ["account_transaction_data": ["account_data": ["id": ["_eq": .variable("accountId")]]]]
      ]),
    ] }

    /// fetch data from the table: "token_transaction"
    public var token_transaction: [Token_transaction] { __data["token_transaction"] }

    /// Token_transaction
    ///
    /// Parent Type: `Token_transaction`
    public struct Token_transaction: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_transaction }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("account_transaction", TubAPI.Uuid.self),
        .field("amount", TubAPI.Numeric.self),
        .field("id", TubAPI.Uuid.self),
        .field("token", TubAPI.Uuid.self),
        .field("token_data", Token_data.self),
        .field("account_transaction_data", Account_transaction_data.self),
        .field("token_price", Token_price?.self),
      ] }

      public var account_transaction: TubAPI.Uuid { __data["account_transaction"] }
      public var amount: TubAPI.Numeric { __data["amount"] }
      public var id: TubAPI.Uuid { __data["id"] }
      public var token: TubAPI.Uuid { __data["token"] }
      /// An object relationship
      public var token_data: Token_data { __data["token_data"] }
      /// An object relationship
      public var account_transaction_data: Account_transaction_data { __data["account_transaction_data"] }
      /// An object relationship
      public var token_price: Token_price? { __data["token_price"] }

      /// Token_transaction.Token_data
      ///
      /// Parent Type: `Token`
      public struct Token_data: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", TubAPI.Uuid.self),
          .field("name", String?.self),
          .field("supply", TubAPI.Numeric?.self),
          .field("symbol", String?.self),
          .field("uri", String?.self),
        ] }

        public var id: TubAPI.Uuid { __data["id"] }
        public var name: String? { __data["name"] }
        public var supply: TubAPI.Numeric? { __data["supply"] }
        public var symbol: String? { __data["symbol"] }
        public var uri: String? { __data["uri"] }
      }

      /// Token_transaction.Account_transaction_data
      ///
      /// Parent Type: `Account_transaction`
      public struct Account_transaction_data: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("created_at", TubAPI.Timestamptz.self),
        ] }

        public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      }

      /// Token_transaction.Token_price
      ///
      /// Parent Type: `Token_price_history`
      public struct Token_price: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_price_history }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("price", TubAPI.Numeric.self),
          .field("created_at", TubAPI.Timestamptz.self),
        ] }

        public var price: TubAPI.Numeric { __data["price"] }
        public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      }
    }
  }
}
