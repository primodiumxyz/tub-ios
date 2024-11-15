// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetWalletTokenBalanceIgnoreIntervalQuery: GraphQLQuery {
  public static let operationName: String = "GetWalletTokenBalanceIgnoreInterval"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetWalletTokenBalanceIgnoreInterval($wallet: String!, $start: timestamptz = "now()", $interval: interval!, $token: String!) { balance: wallet_token_balance_ignore_interval( args: { wallet: $wallet, interval: $interval, start: $start, token: $token } ) { __typename value: balance } }"#
    ))

  public var wallet: String
  public var start: GraphQLNullable<Timestamptz>
  public var interval: Interval
  public var token: String

  public init(
    wallet: String,
    start: GraphQLNullable<Timestamptz> = "now()",
    interval: Interval,
    token: String
  ) {
    self.wallet = wallet
    self.start = start
    self.interval = interval
    self.token = token
  }

  public var __variables: Variables? { [
    "wallet": wallet,
    "start": start,
    "interval": interval,
    "token": token
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("wallet_token_balance_ignore_interval", alias: "balance", [Balance].self, arguments: ["args": [
        "wallet": .variable("wallet"),
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
