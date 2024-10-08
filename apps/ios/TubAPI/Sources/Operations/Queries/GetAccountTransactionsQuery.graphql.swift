// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAccountTransactionsQuery: GraphQLQuery {
  public static let operationName: String = "GetAccountTransactions"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetAccountTransactions($accountId: uuid!) { token_transaction( order_by: { account_transaction_relationship: { created_at: desc } } where: { account_transaction_relationship: { account_relationship: { id: { _eq: $accountId } } } } ) { __typename account_transaction amount id token transaction_type account_transaction_relationship { __typename created_at } } }"#
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
        "order_by": ["account_transaction_relationship": ["created_at": "desc"]],
        "where": ["account_transaction_relationship": ["account_relationship": ["id": ["_eq": .variable("accountId")]]]]
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
        .field("transaction_type", TubAPI.Transaction_type.self),
        .field("account_transaction_relationship", Account_transaction_relationship.self),
      ] }

      public var account_transaction: TubAPI.Uuid { __data["account_transaction"] }
      public var amount: TubAPI.Numeric { __data["amount"] }
      public var id: TubAPI.Uuid { __data["id"] }
      public var token: TubAPI.Uuid { __data["token"] }
      public var transaction_type: TubAPI.Transaction_type { __data["transaction_type"] }
      /// An object relationship
      public var account_transaction_relationship: Account_transaction_relationship { __data["account_transaction_relationship"] }

      /// Token_transaction.Account_transaction_relationship
      ///
      /// Parent Type: `Account_transaction`
      public struct Account_transaction_relationship: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("created_at", TubAPI.Timestamptz.self),
        ] }

        public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      }
    }
  }
}
