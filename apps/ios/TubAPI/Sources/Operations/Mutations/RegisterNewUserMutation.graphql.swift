// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class RegisterNewUserMutation: GraphQLMutation {
  public static let operationName: String = "RegisterNewUser"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation RegisterNewUser($username: String!, $amount: numeric!) { insert_account_one( object: { account_transactions: { data: { amount: $amount, transaction_type: "credit" } } username: $username } ) { __typename id } }"#
    ))

  public var username: String
  public var amount: Numeric

  public init(
    username: String,
    amount: Numeric
  ) {
    self.username = username
    self.amount = amount
  }

  public var __variables: Variables? { [
    "username": username,
    "amount": amount
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_account_one", Insert_account_one?.self, arguments: ["object": [
        "account_transactions": ["data": [
          "amount": .variable("amount"),
          "transaction_type": "credit"
        ]],
        "username": .variable("username")
      ]]),
    ] }

    /// insert a single row into the table: "account"
    public var insert_account_one: Insert_account_one? { __data["insert_account_one"] }

    /// Insert_account_one
    ///
    /// Parent Type: `Account`
    public struct Insert_account_one: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
