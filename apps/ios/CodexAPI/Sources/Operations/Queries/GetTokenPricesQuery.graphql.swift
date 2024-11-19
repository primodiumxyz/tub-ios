// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenPricesQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenPrices"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenPrices($inputs: [GetPriceInput!]!) { getTokenPrices(inputs: $inputs) { __typename timestamp priceUsd } }"#
    ))

  public var inputs: [GetPriceInput]

  public init(inputs: [GetPriceInput]) {
    self.inputs = inputs
  }

  public var __variables: Variables? { ["inputs": inputs] }

  public struct Data: CodexAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("getTokenPrices", [GetTokenPrice?]?.self, arguments: ["inputs": .variable("inputs")]),
    ] }

    /// Returns real-time or historical prices for a list of tokens, fetched in batches.
    public var getTokenPrices: [GetTokenPrice?]? { __data["getTokenPrices"] }

    /// GetTokenPrice
    ///
    /// Parent Type: `Price`
    public struct GetTokenPrice: CodexAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Price }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("timestamp", Int.self),
        .field("priceUsd", Double.self),
      ] }

      /// The unix timestamp for the price.
      public var timestamp: Int { __data["timestamp"] }
      /// The token price in USD.
      public var priceUsd: Double { __data["priceUsd"] }
    }
  }
}
