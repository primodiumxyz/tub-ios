// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenPriceQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenPrice"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenPrice($tokenId: uuid!) { token_price_history( where: { token: { _eq: $tokenId } } order_by: { created_at: desc } limit: 1 ) { __typename created_at id price token } }"#
    ))

  public var tokenId: Uuid

  public init(tokenId: Uuid) {
    self.tokenId = tokenId
  }

  public var __variables: Variables? { ["tokenId": tokenId] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_price_history", [Token_price_history].self, arguments: [
        "where": ["token": ["_eq": .variable("tokenId")]],
        "order_by": ["created_at": "desc"],
        "limit": 1
      ]),
    ] }

    /// fetch data from the table: "token_price_history"
    public var token_price_history: [Token_price_history] { __data["token_price_history"] }

    /// Token_price_history
    ///
    /// Parent Type: `Token_price_history`
    public struct Token_price_history: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_price_history }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("created_at", TubAPI.Timestamptz.self),
        .field("id", TubAPI.Uuid.self),
        .field("price", TubAPI.Numeric.self),
        .field("token", TubAPI.Uuid.self),
      ] }

      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      public var id: TubAPI.Uuid { __data["id"] }
      public var price: TubAPI.Numeric { __data["price"] }
      public var token: TubAPI.Uuid { __data["token"] }
    }
  }
}
