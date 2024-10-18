// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAccountTokenBalanceIgnoreIntervalQuery: GraphQLQuery {
  public static let operationName: String = "GetAccountTokenBalanceIgnoreInterval"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetAccountTokenBalanceIgnoreInterval($account: uuid!, $start: timestamptz = "now()", $interval: interval!, $token: uuid!) { balance: account_token_balance_ignore_interval( args: { account: $account, interval: $interval, start: $start, token: $token } ) { __typename value: balance } }"#
    ))

  public var account: Uuid
  public var start: GraphQLNullable<Timestamptz>
  public var interval: Interval
  public var token: Uuid

  public init(
    account: Uuid,
    start: GraphQLNullable<Timestamptz> = "now()",
    interval: Interval,
    token: Uuid
  ) {
    self.account = account
    self.start = start
    self.interval = interval
    self.token = token
  }

  public var __variables: Variables? { [
    "account": account,
    "start": start,
    "interval": interval,
    "token": token
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("account_token_balance_ignore_interval", alias: "balance", [Balance].self, arguments: ["args": [
        "account": .variable("account"),
        "interval": .variable("interval"),
        "start": .variable("start"),
        "token": .variable("token")
      ]]),
    ] }

    public var balance: [Balance] { __data["balance"] }

    /// Balance
    ///
    /// Parent Type: `Balance_offset_model`
    public struct Balance: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Balance_offset_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("balance", alias: "value", TubAPI.Numeric.self),
      ] }

      public var value: TubAPI.Numeric { __data["value"] }
    }
  }
}
