// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokensByMintsQuery: GraphQLQuery {
  public static let operationName: String = "GetTokensByMints"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokensByMints($mints: [String!]!) { token(where: { mint: { _in: $mints } }) { __typename id mint } }"#
    ))

  public var mints: [String]

  public init(mints: [String]) {
    self.mints = mints
  }

  public var __variables: Variables? { ["mints": mints] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token", [Token].self, arguments: ["where": ["mint": ["_in": .variable("mints")]]]),
    ] }

    /// fetch data from the table: "token"
    public var token: [Token] { __data["token"] }

    /// Token
    ///
    /// Parent Type: `Token`
    public struct Token: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
        .field("mint", String?.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
      /// token mint address (only for real tokens)
      public var mint: String? { __data["mint"] }
    }
  }
}
