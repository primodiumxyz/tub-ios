// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAccountTokenBalanceQuery: GraphQLQuery {
  public static let operationName: String = "GetAccountTokenBalance"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetAccountTokenBalance($accountId: uuid!, $tokenId: uuid!) { credit: token_transaction_aggregate( where: { account_transaction_data: { account: { _eq: $accountId } } token: { _eq: $tokenId } transaction_type: { _eq: "credit" } } ) { __typename aggregate { __typename sum { __typename amount } } } debit: token_transaction_aggregate( where: { account_transaction_data: { account: { _eq: $accountId } } token: { _eq: $tokenId } transaction_type: { _eq: "debit" } } ) { __typename aggregate { __typename sum { __typename amount } } } }"#
    ))

  public var accountId: Uuid
  public var tokenId: Uuid

  public init(
    accountId: Uuid,
    tokenId: Uuid
  ) {
    self.accountId = accountId
    self.tokenId = tokenId
  }

  public var __variables: Variables? { [
    "accountId": accountId,
    "tokenId": tokenId
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_transaction_aggregate", alias: "credit", Credit.self, arguments: ["where": [
        "account_transaction_data": ["account": ["_eq": .variable("accountId")]],
        "token": ["_eq": .variable("tokenId")],
        "transaction_type": ["_eq": "credit"]
      ]]),
      .field("token_transaction_aggregate", alias: "debit", Debit.self, arguments: ["where": [
        "account_transaction_data": ["account": ["_eq": .variable("accountId")]],
        "token": ["_eq": .variable("tokenId")],
        "transaction_type": ["_eq": "debit"]
      ]]),
    ] }

    /// fetch aggregated fields from the table: "token_transaction"
    public var credit: Credit { __data["credit"] }
    /// fetch aggregated fields from the table: "token_transaction"
    public var debit: Debit { __data["debit"] }

    /// Credit
    ///
    /// Parent Type: `Token_transaction_aggregate`
    public struct Credit: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_transaction_aggregate }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("aggregate", Aggregate?.self),
      ] }

      public var aggregate: Aggregate? { __data["aggregate"] }

      /// Credit.Aggregate
      ///
      /// Parent Type: `Token_transaction_aggregate_fields`
      public struct Aggregate: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_transaction_aggregate_fields }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("sum", Sum?.self),
        ] }

        public var sum: Sum? { __data["sum"] }

        /// Credit.Aggregate.Sum
        ///
        /// Parent Type: `Token_transaction_sum_fields`
        public struct Sum: TubAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_transaction_sum_fields }
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
    /// Parent Type: `Token_transaction_aggregate`
    public struct Debit: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_transaction_aggregate }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("aggregate", Aggregate?.self),
      ] }

      public var aggregate: Aggregate? { __data["aggregate"] }

      /// Debit.Aggregate
      ///
      /// Parent Type: `Token_transaction_aggregate_fields`
      public struct Aggregate: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_transaction_aggregate_fields }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("sum", Sum?.self),
        ] }

        public var sum: Sum? { __data["sum"] }

        /// Debit.Aggregate.Sum
        ///
        /// Parent Type: `Token_transaction_sum_fields`
        public struct Sum: TubAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_transaction_sum_fields }
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
