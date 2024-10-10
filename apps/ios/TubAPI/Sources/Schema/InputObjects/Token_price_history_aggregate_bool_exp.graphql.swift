// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct Token_price_history_aggregate_bool_exp: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    count: GraphQLNullable<Token_price_history_aggregate_bool_exp_count> = nil
  ) {
    __data = InputDict([
      "count": count
    ])
  }

  public var count: GraphQLNullable<Token_price_history_aggregate_bool_exp_count> {
    get { __data["count"] }
    set { __data["count"] = newValue }
  }
}
