// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetAllTokensQuery: GraphQLQuery {
  public static let operationName: String = "GetAllTokens"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetAllTokens { token { __typename id name symbol updated_at supply uri } }"#
    ))

  public init() {}

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token", [Token].self),
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
        .field("name", String.self),
        .field("symbol", String.self),
        .field("updated_at", TubAPI.Timestamp.self),
        .field("supply", TubAPI.Numeric.self),
        .field("uri", String?.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
      public var name: String { __data["name"] }
      public var symbol: String { __data["symbol"] }
      public var updated_at: TubAPI.Timestamp { __data["updated_at"] }
      public var supply: TubAPI.Numeric { __data["supply"] }
      public var uri: String? { __data["uri"] }
    }
  }
}
