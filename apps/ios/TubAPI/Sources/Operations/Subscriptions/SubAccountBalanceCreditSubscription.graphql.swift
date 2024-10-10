// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubAccountBalanceCreditSubscription: GraphQLSubscription {
  public static let operationName: String = "SubAccountBalanceCredit"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubAccountBalanceCredit($accountId: uuid!) { account_transaction_aggregate( where: { account: { _eq: $accountId }, transaction_type: { _eq: "credit" } } ) { __typename aggregate { __typename sum { __typename amount } } } }"#
    ))

  public var accountId: Uuid

  public init(accountId: Uuid) {
    self.accountId = accountId
  }

  public var __variables: Variables? { ["accountId": accountId] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("account_transaction_aggregate", Account_transaction_aggregate.self, arguments: ["where": [
        "account": ["_eq": .variable("accountId")],
        "transaction_type": ["_eq": "credit"]
      ]]),
    ] }

    /// fetch aggregated fields from the table: "account_transaction"
    public var account_transaction_aggregate: Account_transaction_aggregate { __data["account_transaction_aggregate"] }

    /// Account_transaction_aggregate
    ///
    /// Parent Type: `Account_transaction_aggregate`
    public struct Account_transaction_aggregate: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction_aggregate }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("aggregate", Aggregate?.self),
      ] }

      public var aggregate: Aggregate? { __data["aggregate"] }

      /// Account_transaction_aggregate.Aggregate
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

        /// Account_transaction_aggregate.Aggregate.Sum
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
