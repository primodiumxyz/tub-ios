// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubTokenPricesSubscription: GraphQLSubscription {
  public static let operationName: String = "SubTokenPrices"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubTokenPrices($address: String!, $networkId: Int = 1399811149) { onPriceUpdated(address: $address, networkId: $networkId) { __typename timestamp priceUsd } }"#
    ))

  public var address: String
  public var networkId: GraphQLNullable<Int>

  public init(
    address: String,
    networkId: GraphQLNullable<Int> = 1399811149
  ) {
    self.address = address
    self.networkId = networkId
  }

  public var __variables: Variables? { [
    "address": address,
    "networkId": networkId
  ] }

  public struct Data: CodexAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Subscription }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("onPriceUpdated", OnPriceUpdated?.self, arguments: [
        "address": .variable("address"),
        "networkId": .variable("networkId")
      ]),
    ] }

    /// Live-streamed price updates for a token.
    public var onPriceUpdated: OnPriceUpdated? { __data["onPriceUpdated"] }

    /// OnPriceUpdated
    ///
    /// Parent Type: `Price`
    public struct OnPriceUpdated: CodexAPI.SelectionSet {
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
