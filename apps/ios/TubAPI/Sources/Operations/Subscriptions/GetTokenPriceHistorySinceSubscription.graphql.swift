// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenPriceHistorySinceSubscription: GraphQLSubscription {
  public static let operationName: String = "GetTokenPriceHistorySince"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription GetTokenPriceHistorySince($tokenId: uuid!, $since: timestamp!) { token_price_history( where: { token: { _eq: $tokenId }, created_at: { _gte: $since } } limit: 100 order_by: { created_at: desc } ) { __typename created_at id price token } }"#
    ))

  public var tokenId: Uuid
  public var since: Timestamp

  public init(
    tokenId: Uuid,
    since: Timestamp
  ) {
    self.tokenId = tokenId
    self.since = since
  }

  public var __variables: Variables? { [
    "tokenId": tokenId,
    "since": since
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_price_history", [Token_price_history].self, arguments: [
        "where": [
          "token": ["_eq": .variable("tokenId")],
          "created_at": ["_gte": .variable("since")]
        ],
        "limit": 100,
        "order_by": ["created_at": "desc"]
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
        .field("created_at", TubAPI.Timestamp.self),
        .field("id", TubAPI.Uuid.self),
        .field("price", TubAPI.Numeric.self),
        .field("token", TubAPI.Uuid.self),
      ] }

      public var created_at: TubAPI.Timestamp { __data["created_at"] }
      public var id: TubAPI.Uuid { __data["id"] }
      public var price: TubAPI.Numeric { __data["price"] }
      public var token: TubAPI.Uuid { __data["token"] }
    }
  }
}
