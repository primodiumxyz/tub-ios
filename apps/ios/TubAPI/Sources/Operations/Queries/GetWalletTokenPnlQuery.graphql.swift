// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetWalletTokenPnlQuery: GraphQLQuery {
  public static let operationName: String = "GetWalletTokenPnl"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetWalletTokenPnl($wallet: String!, $token_mint: String!) { transactions_value_aggregate( where: { user_wallet: { _eq: $wallet }, token_mint: { _eq: $token_mint } } ) { __typename total_value_usd } }"#
    ))

  public var wallet: String
  public var token_mint: String

  public init(
    wallet: String,
    token_mint: String
  ) {
    self.wallet = wallet
    self.token_mint = token_mint
  }

  public var __variables: Variables? { [
    "wallet": wallet,
    "token_mint": token_mint
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("transactions_value_aggregate", [Transactions_value_aggregate].self, arguments: ["where": [
        "user_wallet": ["_eq": .variable("wallet")],
        "token_mint": ["_eq": .variable("token_mint")]
      ]]),
    ] }

    public var transactions_value_aggregate: [Transactions_value_aggregate] { __data["transactions_value_aggregate"] }

    /// Transactions_value_aggregate
    ///
    /// Parent Type: `Wallet_token_pnl_model`
    public struct Transactions_value_aggregate: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Wallet_token_pnl_model }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("total_value_usd", TubAPI.Numeric.self),
      ] }

      public var total_value_usd: TubAPI.Numeric { __data["total_value_usd"] }
    }
  }
}
