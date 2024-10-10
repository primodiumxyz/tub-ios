// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAccountDataQuery: GraphQLQuery {
  public static let operationName: String = "GetAccountData"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetAccountData($accountId: uuid!) { account(where: { id: { _eq: $accountId } }) { __typename username id created_at } }"#
    ))

  public var accountId: Uuid

  public init(accountId: Uuid) {
    self.accountId = accountId
  }

  public var __variables: Variables? { ["accountId": accountId] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("account", [Account].self, arguments: ["where": ["id": ["_eq": .variable("accountId")]]]),
    ] }

    /// fetch data from the table: "account"
    public var account: [Account] { __data["account"] }

    /// Account
    ///
    /// Parent Type: `Account`
    public struct Account: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Account }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("username", String.self),
        .field("id", TubAPI.Uuid.self),
        .field("created_at", TubAPI.Timestamptz.self),
      ] }

      public var username: String { __data["username"] }
      public var id: TubAPI.Uuid { __data["id"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
    }
  }
}
