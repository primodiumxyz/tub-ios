// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAccountTokenBalanceCreditQuery: GraphQLQuery {
  public static let operationName: String = "GetAccountTokenBalanceCredit"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetAccountTokenBalanceCredit($accountId: uuid!, $tokenId: uuid!) { token_transaction_aggregate( where: { account_transaction_data: { account: { _eq: $accountId } } token: { _eq: $tokenId } transaction_type: { _eq: "credit" } } ) { __typename aggregate { __typename sum { __typename amount } } } }"#
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
      .field("token_transaction_aggregate", Token_transaction_aggregate.self, arguments: ["where": [
        "account_transaction_data": ["account": ["_eq": .variable("accountId")]],
        "token": ["_eq": .variable("tokenId")],
        "transaction_type": ["_eq": "credit"]
      ]]),
    ] }

    /// fetch aggregated fields from the table: "token_transaction"
    public var token_transaction_aggregate: Token_transaction_aggregate { __data["token_transaction_aggregate"] }

    /// Token_transaction_aggregate
    ///
    /// Parent Type: `Token_transaction_aggregate`
    public struct Token_transaction_aggregate: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_transaction_aggregate }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("aggregate", Aggregate?.self),
      ] }

      public var aggregate: Aggregate? { __data["aggregate"] }

      /// Token_transaction_aggregate.Aggregate
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

        /// Token_transaction_aggregate.Aggregate.Sum
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
