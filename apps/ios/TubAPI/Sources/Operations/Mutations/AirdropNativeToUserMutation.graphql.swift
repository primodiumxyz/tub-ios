// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class AirdropNativeToUserMutation: GraphQLMutation {
  public static let operationName: String = "AirdropNativeToUser"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AirdropNativeToUser($wallet: String!, $amount: numeric!) { insert_wallet_transaction_one(object: { wallet: $wallet, amount: $amount }) { __typename id } }"#
    ))

  public var wallet: String
  public var amount: Numeric

  public init(
    wallet: String,
    amount: Numeric
  ) {
    self.wallet = wallet
    self.amount = amount
  }

  public var __variables: Variables? { [
    "wallet": wallet,
    "amount": amount
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_wallet_transaction_one", Insert_wallet_transaction_one?.self, arguments: ["object": [
        "wallet": .variable("wallet"),
        "amount": .variable("amount")
      ]]),
    ] }

    /// insert a single row into the table: "wallet_transaction"
    public var insert_wallet_transaction_one: Insert_wallet_transaction_one? { __data["insert_wallet_transaction_one"] }

    /// Insert_wallet_transaction_one
    ///
    /// Parent Type: `Wallet_transaction`
    public struct Insert_wallet_transaction_one: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Wallet_transaction }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
