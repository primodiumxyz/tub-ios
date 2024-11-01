// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetWalletBalanceQuery: GraphQLQuery {
  public static let operationName: String = "GetWalletBalance"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetWalletBalance($wallet: String!, $start: timestamptz = "now()") { balance: wallet_balance_ignore_interval( args: { wallet: $wallet, interval: "0", start: $start } ) { __typename value: balance } }"#
    ))

  public var wallet: String
  public var start: GraphQLNullable<Timestamptz>

  public init(
    wallet: String,
    start: GraphQLNullable<Timestamptz> = "now()"
  ) {
    self.wallet = wallet
    self.start = start
  }

  public var __variables: Variables? { [
    "wallet": wallet,
    "start": start
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("wallet_balance_ignore_interval", alias: "balance", [Balance].self, arguments: ["args": [
        "wallet": .variable("wallet"),
        "interval": "0",
        "start": .variable("start")
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
