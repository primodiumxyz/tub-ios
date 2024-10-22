// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAccountTokenBalanceQuery: GraphQLQuery {
  public static let operationName: String = "GetAccountTokenBalance"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetAccountTokenBalance($account: uuid!, $token: uuid!, $start: timestamptz = "now()") { balance: account_token_balance_ignore_interval( args: { account: $account, interval: "0", start: $start, token: $token } ) { __typename value: balance } }"#
    ))

  public var account: Uuid
  public var token: Uuid
  public var start: GraphQLNullable<Timestamptz>

  public init(
    account: Uuid,
    token: Uuid,
    start: GraphQLNullable<Timestamptz> = "now()"
  ) {
    self.account = account
    self.token = token
    self.start = start
  }

  public var __variables: Variables? { [
    "account": account,
    "token": token,
    "start": start
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("account_token_balance_ignore_interval", alias: "balance", [Balance].self, arguments: ["args": [
        "account": .variable("account"),
        "interval": "0",
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
