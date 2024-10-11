// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubAllOnchainTokensPriceHistorySinceSubscription: GraphQLSubscription {
  public static let operationName: String = "SubAllOnchainTokensPriceHistorySince"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubAllOnchainTokensPriceHistorySince($since: timestamptz!) { token_price_history( where: { token_relationship: { mint: { _is_null: false } } created_at: { _gte: $since } } order_by: { created_at: desc } ) { __typename created_at id price token_relationship { __typename mint name } } }"#
    ))

  public var since: Timestamptz

  public init(since: Timestamptz) {
    self.since = since
  }

  public var __variables: Variables? { ["since": since] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token_price_history", [Token_price_history].self, arguments: [
        "where": [
          "token_relationship": ["mint": ["_is_null": false]],
          "created_at": ["_gte": .variable("since")]
        ],
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
        .field("created_at", TubAPI.Timestamptz.self),
        .field("id", TubAPI.Uuid.self),
        .field("price", TubAPI.Numeric.self),
        .field("token_relationship", Token_relationship.self),
      ] }

      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
      public var id: TubAPI.Uuid { __data["id"] }
      public var price: TubAPI.Numeric { __data["price"] }
      /// An object relationship
      public var token_relationship: Token_relationship { __data["token_relationship"] }

      /// Token_price_history.Token_relationship
      ///
      /// Parent Type: `Token`
      public struct Token_relationship: TubAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("mint", String?.self),
          .field("name", String.self),
        ] }

        /// token mint address (only for real tokens)
        public var mint: String? { __data["mint"] }
        public var name: String { __data["name"] }
      }
    }
  }
}
