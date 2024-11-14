// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// Input type of `getTokenPrices`.
public struct GetPriceInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    address: String,
    networkId: Int,
    timestamp: GraphQLNullable<Int> = nil
  ) {
    __data = InputDict([
      "address": address,
      "networkId": networkId,
      "timestamp": timestamp
    ])
  }

  @available(*, deprecated, message: "Argument 'maxDeviations' is deprecated.")
  public init(
    address: String,
    networkId: Int,
    timestamp: GraphQLNullable<Int> = nil,
    maxDeviations: GraphQLNullable<Double> = nil
  ) {
    __data = InputDict([
      "address": address,
      "networkId": networkId,
      "timestamp": timestamp,
      "maxDeviations": maxDeviations
    ])
  }

  /// The contract address of the token.
  public var address: String {
    get { __data["address"] }
    set { __data["address"] = newValue }
  }

  /// The network ID the token is deployed on.
  public var networkId: Int {
    get { __data["networkId"] }
    set { __data["networkId"] = newValue }
  }

  /// The unix timestamp for the price.
  public var timestamp: GraphQLNullable<Int> {
    get { __data["timestamp"] }
    set { __data["timestamp"] = newValue }
  }

  /// The maximum number of deviations from the token's Liquidity-Weighted Mean Price. This is used to mitigate low liquidity pairs producing prices that are not representative of reality. Default is `1`.
  @available(*, deprecated, message: "This isn\'t taken into account anymore.")
  public var maxDeviations: GraphQLNullable<Double> {
    get { __data["maxDeviations"] }
    set { __data["maxDeviations"] = newValue }
  }
}
