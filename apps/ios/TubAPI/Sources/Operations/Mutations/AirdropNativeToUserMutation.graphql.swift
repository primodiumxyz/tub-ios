// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class AirdropNativeToUserMutation: GraphQLMutation {
  public static let operationName: String = "AirdropNativeToUser"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AirdropNativeToUser($account: uuid!, $amount: numeric!) { insert_account_transaction_one(object: { account: $account, amount: $amount }) { __typename id } }"#
    ))

  public var account: Uuid
  public var amount: Numeric

  public init(
    account: Uuid,
    amount: Numeric
  ) {
    self.account = account
    self.amount = amount
  }

  public var __variables: Variables? { [
    "account": account,
    "amount": amount
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_account_transaction_one", Insert_account_transaction_one?.self, arguments: ["object": [
        "account": .variable("account"),
        "amount": .variable("amount")
      ]]),
    ] }

    /// insert a single row into the table: "account_transaction"
    public var insert_account_transaction_one: Insert_account_transaction_one? { __data["insert_account_transaction_one"] }

    /// Insert_account_transaction_one
    ///
    /// Parent Type: `Account_transaction`
    public struct Insert_account_transaction_one: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account_transaction }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
