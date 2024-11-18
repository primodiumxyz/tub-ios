// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetUniqueHoldersQuery: GraphQLQuery {
  public static let operationName: String = "GetUniqueHolders"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetUniqueHolders($pairId: String!) { holders(input: { tokenId: $pairId }) { __typename count } }"#
    ))

  public var pairId: String

  public init(pairId: String) {
    self.pairId = pairId
  }

  public var __variables: Variables? { ["pairId": pairId] }

  public struct Data: CodexAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("holders", Holders.self, arguments: ["input": ["tokenId": .variable("pairId")]]),
    ] }

    /// Returns list of wallets that hold a given token, ordered by holdings descending. Also has the unique count of holders for that token
    public var holders: Holders { __data["holders"] }

    /// Holders
    ///
    /// Parent Type: `HoldersResponse`
    public struct Holders: CodexAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.HoldersResponse }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("count", Int.self),
      ] }

      /// the unique count of holders for the token.
      public var count: Int { __data["count"] }
    }
  }
}
