// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// Boolean expression to compare columns of type "uuid". All fields are combined with logical 'AND'.
public struct Uuid_comparison_exp: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    _eq: GraphQLNullable<Uuid> = nil,
    _gt: GraphQLNullable<Uuid> = nil,
    _gte: GraphQLNullable<Uuid> = nil,
    _in: GraphQLNullable<[Uuid]> = nil,
    _isNull: GraphQLNullable<Bool> = nil,
    _lt: GraphQLNullable<Uuid> = nil,
    _lte: GraphQLNullable<Uuid> = nil,
    _neq: GraphQLNullable<Uuid> = nil,
    _nin: GraphQLNullable<[Uuid]> = nil
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

  public var _eq: GraphQLNullable<Uuid> {
    get { __data["_eq"] }
    set { __data["_eq"] = newValue }
  }

  public var _gt: GraphQLNullable<Uuid> {
    get { __data["_gt"] }
    set { __data["_gt"] = newValue }
  }

  public var _gte: GraphQLNullable<Uuid> {
    get { __data["_gte"] }
    set { __data["_gte"] = newValue }
  }

  public var _in: GraphQLNullable<[Uuid]> {
    get { __data["_in"] }
    set { __data["_in"] = newValue }
  }

  public var _isNull: GraphQLNullable<Bool> {
    get { __data["_is_null"] }
    set { __data["_is_null"] = newValue }
  }

  public var _lt: GraphQLNullable<Uuid> {
    get { __data["_lt"] }
    set { __data["_lt"] = newValue }
  }

  public var _lte: GraphQLNullable<Uuid> {
    get { __data["_lte"] }
    set { __data["_lte"] = newValue }
  }

  public var _neq: GraphQLNullable<Uuid> {
    get { __data["_neq"] }
    set { __data["_neq"] = newValue }
  }

  public var _nin: GraphQLNullable<[Uuid]> {
    get { __data["_nin"] }
    set { __data["_nin"] = newValue }
  }
}
