// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubTokenCandlesSubscription: GraphQLSubscription {
  public static let operationName: String = "SubTokenCandles"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubTokenCandles($pairId: String!) { onBarsUpdated(pairId: $pairId) { __typename aggregates { __typename r1 { __typename token { __typename o h l c v t } } } } }"#
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
      .field("onBarsUpdated", OnBarsUpdated?.self, arguments: ["pairId": .variable("pairId")]),
    ] }

    /// Live-streamed bar chart data to track price changes over time.
    public var onBarsUpdated: OnBarsUpdated? { __data["onBarsUpdated"] }

    /// OnBarsUpdated
    ///
    /// Parent Type: `OnBarsUpdatedResponse`
    public struct OnBarsUpdated: CodexAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.OnBarsUpdatedResponse }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("aggregates", Aggregates.self),
      ] }

      /// Price data broken down by resolution.
      public var aggregates: Aggregates { __data["aggregates"] }

      /// OnBarsUpdated.Aggregates
      ///
      /// Parent Type: `ResolutionBarData`
      public struct Aggregates: CodexAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.ResolutionBarData }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("r1", R1?.self),
        ] }

        /// 1 minute resolution.
        public var r1: R1? { __data["r1"] }

        /// OnBarsUpdated.Aggregates.R1
        ///
        /// Parent Type: `CurrencyBarData`
        public struct R1: CodexAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.CurrencyBarData }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("token", Token.self),
          ] }

          /// Bar chart data in the network's base token.
          public var token: Token { __data["token"] }

          /// OnBarsUpdated.Aggregates.R1.Token
          ///
          /// Parent Type: `IndividualBarData`
          public struct Token: CodexAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.IndividualBarData }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("o", Double.self),
              .field("h", Double.self),
              .field("l", Double.self),
              .field("c", Double.self),
              .field("v", Int?.self),
              .field("t", Int.self),
            ] }

            /// The opening price.
            public var o: Double { __data["o"] }
            /// The high price.
            public var h: Double { __data["h"] }
            /// The low price.
            public var l: Double { __data["l"] }
            /// The closing price.
            public var c: Double { __data["c"] }
            /// The volume.
            public var v: Int? { __data["v"] }
            /// The timestamp for the bar.
            public var t: Int { __data["t"] }
          }
        }
      }
    }
  }
}
