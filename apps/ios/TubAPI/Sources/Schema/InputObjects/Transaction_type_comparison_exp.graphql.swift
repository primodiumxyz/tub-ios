// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// Boolean expression to compare columns of type "transaction_type". All fields are combined with logical 'AND'.
public struct Transaction_type_comparison_exp: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    _eq: GraphQLNullable<Transaction_type> = nil,
    _gt: GraphQLNullable<Transaction_type> = nil,
    _gte: GraphQLNullable<Transaction_type> = nil,
    _in: GraphQLNullable<[Transaction_type]> = nil,
    _isNull: GraphQLNullable<Bool> = nil,
    _lt: GraphQLNullable<Transaction_type> = nil,
    _lte: GraphQLNullable<Transaction_type> = nil,
    _neq: GraphQLNullable<Transaction_type> = nil,
    _nin: GraphQLNullable<[Transaction_type]> = nil
  ) {
    __data = InputDict([
      "_eq": _eq,
      "_gt": _gt,
      "_gte": _gte,
      "_in": _in,
      "_is_null": _isNull,
      "_lt": _lt,
      "_lte": _lte,
      "_neq": _neq,
      "_nin": _nin
    ])
  }

  public var _eq: GraphQLNullable<Transaction_type> {
    get { __data["_eq"] }
    set { __data["_eq"] = newValue }
  }

  public var _gt: GraphQLNullable<Transaction_type> {
    get { __data["_gt"] }
    set { __data["_gt"] = newValue }
  }

  public var _gte: GraphQLNullable<Transaction_type> {
    get { __data["_gte"] }
    set { __data["_gte"] = newValue }
  }

  public var _in: GraphQLNullable<[Transaction_type]> {
    get { __data["_in"] }
    set { __data["_in"] = newValue }
  }

  public var _isNull: GraphQLNullable<Bool> {
    get { __data["_is_null"] }
    set { __data["_is_null"] = newValue }
  }

  public var _lt: GraphQLNullable<Transaction_type> {
    get { __data["_lt"] }
    set { __data["_lt"] = newValue }
  }

  public var _lte: GraphQLNullable<Transaction_type> {
    get { __data["_lte"] }
    set { __data["_lte"] = newValue }
  }

  public var _neq: GraphQLNullable<Transaction_type> {
    get { __data["_neq"] }
    set { __data["_neq"] = newValue }
  }

  public var _nin: GraphQLNullable<[Transaction_type]> {
    get { __data["_nin"] }
    set { __data["_nin"] = newValue }
  }
}
