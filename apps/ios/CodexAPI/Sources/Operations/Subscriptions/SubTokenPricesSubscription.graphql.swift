// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubTokenPricesSubscription: GraphQLSubscription {
  public static let operationName: String = "SubTokenPrices"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubTokenPrices($pairId: String!) { onEventsCreated(id: $pairId) { __typename events { __typename eventType timestamp token0PoolValueUsd token1PoolValueUsd quoteToken } } }"#
    ))

  public var pairId: String

  public init(pairId: String) {
    self.pairId = pairId
  }

  public var __variables: Variables? { ["pairId": pairId] }

  public struct Data: CodexAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Subscription }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("onEventsCreated", OnEventsCreated?.self, arguments: ["id": .variable("pairId")]),
    ] }

    /// Live-streamed transactions for a token.
    public var onEventsCreated: OnEventsCreated? { __data["onEventsCreated"] }

    /// OnEventsCreated
    ///
    /// Parent Type: `AddEventsOutput`
    public struct OnEventsCreated: CodexAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.AddEventsOutput }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("events", [Event?].self),
      ] }

      /// A list of transactions for the token.
      public var events: [Event?] { __data["events"] }

      /// OnEventsCreated.Event
      ///
      /// Parent Type: `Event`
      public struct Event: CodexAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Event }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("eventType", GraphQLEnum<CodexAPI.EventType>.self),
          .field("timestamp", Int.self),
          .field("token0PoolValueUsd", String?.self),
          .field("token1PoolValueUsd", String?.self),
          .field("quoteToken", GraphQLEnum<CodexAPI.QuoteToken>?.self),
        ] }

        /// The type of transaction event. Can be `Burn`, `Mint`, `Swap`, `Sync`, `Collect`, or `CollectProtocol`.
        public var eventType: GraphQLEnum<CodexAPI.EventType> { __data["eventType"] }
        /// The unix timestamp for when the transaction occurred.
        public var timestamp: Int { __data["timestamp"] }
        /// The updated price of `token0` in USD, calculated after the transaction.
        public var token0PoolValueUsd: String? { __data["token0PoolValueUsd"] }
        /// The updated price of `token1` in USD, calculated after the transaction.
        public var token1PoolValueUsd: String? { __data["token1PoolValueUsd"] }
        /// The token of interest within the token's top pair. Can be `token0` or `token1`.
        public var quoteToken: GraphQLEnum<CodexAPI.QuoteToken>? { __data["quoteToken"] }
      }
    }
  }
}
