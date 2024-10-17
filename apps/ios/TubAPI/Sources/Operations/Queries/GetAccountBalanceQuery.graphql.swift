// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAccountBalanceQuery: GraphQLQuery {
  public static let operationName: String = "GetAccountBalance"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetAccountBalance($accountId: uuid!, $at: timestamptz!) { credit: account_transaction_aggregate( where: { account: { _eq: $accountId } created_at: { _lte: $at } transaction_type: { _eq: "credit" } } ) { __typename aggregate { __typename sum { __typename amount } } } debit: account_transaction_aggregate( where: { account: { _eq: $accountId } created_at: { _lte: $at } transaction_type: { _eq: "debit" } } ) { __typename aggregate { __typename sum { __typename amount } } } }"#
    ))

  public var accountId: Uuid
  public var at: Timestamptz

  public init(
    accountId: Uuid,
    at: Timestamptz
  ) {
    self.accountId = accountId
    self.at = at
  }

  public var __variables: Variables? { [
    "accountId": accountId,
    "at": at
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("account_transaction_aggregate", alias: "credit", Credit.self, arguments: ["where": [
        "account": ["_eq": .variable("accountId")],
        "created_at": ["_lte": .variable("at")],
        "transaction_type": ["_eq": "credit"]
      ]]),
      .field("account_transaction_aggregate", alias: "debit", Debit.self, arguments: ["where": [
        "account": ["_eq": .variable("accountId")],
        "created_at": ["_lte": .variable("at")],
        "transaction_type": ["_eq": "debit"]
      ]]),
    ] }

    /// fetch aggregated fields from the table: "account_transaction"
    public var credit: Credit { __data["credit"] }
    /// fetch aggregated fields from the table: "account_transaction"
    public var debit: Debit { __data["debit"] }

    /// Credit
    ///
    /// Parent Type: `Account_transaction_aggregate`
    public struct Credit: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction_aggregate }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("aggregate", Aggregate?.self),
      ] }

      public var aggregate: Aggregate? { __data["aggregate"] }

      /// Credit.Aggregate
      ///
      /// Parent Type: `Account_transaction_aggregate_fields`
      public struct Aggregate: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction_aggregate_fields }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("sum", Sum?.self),
        ] }

        public var sum: Sum? { __data["sum"] }

        /// Credit.Aggregate.Sum
        ///
        /// Parent Type: `Account_transaction_sum_fields`
        public struct Sum: TubAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction_sum_fields }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("amount", TubAPI.Numeric?.self),
          ] }

          public var amount: TubAPI.Numeric? { __data["amount"] }
        }
      }
    }

    /// Debit
    ///
    /// Parent Type: `Account_transaction_aggregate`
    public struct Debit: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction_aggregate }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("aggregate", Aggregate?.self),
      ] }

      public var aggregate: Aggregate? { __data["aggregate"] }

      /// Debit.Aggregate
      ///
      /// Parent Type: `Account_transaction_aggregate_fields`
      public struct Aggregate: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction_aggregate_fields }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("sum", Sum?.self),
        ] }

        public var sum: Sum? { __data["sum"] }

        /// Debit.Aggregate.Sum
        ///
        /// Parent Type: `Account_transaction_sum_fields`
        public struct Sum: TubAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction_sum_fields }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("amount", TubAPI.Numeric?.self),
          ] }

          public var amount: TubAPI.Numeric? { __data["amount"] }
        }
      }
    }
  }
}
