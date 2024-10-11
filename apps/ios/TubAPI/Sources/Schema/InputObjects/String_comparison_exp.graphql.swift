// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// Boolean expression to compare columns of type "String". All fields are combined with logical 'AND'.
public struct String_comparison_exp: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    _eq: GraphQLNullable<String> = nil,
    _gt: GraphQLNullable<String> = nil,
    _gte: GraphQLNullable<String> = nil,
    _ilike: GraphQLNullable<String> = nil,
    _in: GraphQLNullable<[String]> = nil,
    _iregex: GraphQLNullable<String> = nil,
    _isNull: GraphQLNullable<Bool> = nil,
    _like: GraphQLNullable<String> = nil,
    _lt: GraphQLNullable<String> = nil,
    _lte: GraphQLNullable<String> = nil,
    _neq: GraphQLNullable<String> = nil,
    _nilike: GraphQLNullable<String> = nil,
    _nin: GraphQLNullable<[String]> = nil,
    _niregex: GraphQLNullable<String> = nil,
    _nlike: GraphQLNullable<String> = nil,
    _nregex: GraphQLNullable<String> = nil,
    _nsimilar: GraphQLNullable<String> = nil,
    _regex: GraphQLNullable<String> = nil,
    _similar: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "_eq": _eq,
      "_gt": _gt,
      "_gte": _gte,
      "_ilike": _ilike,
      "_in": _in,
      "_iregex": _iregex,
      "_is_null": _isNull,
      "_like": _like,
      "_lt": _lt,
      "_lte": _lte,
      "_neq": _neq,
      "_nilike": _nilike,
      "_nin": _nin,
      "_niregex": _niregex,
      "_nlike": _nlike,
      "_nregex": _nregex,
      "_nsimilar": _nsimilar,
      "_regex": _regex,
      "_similar": _similar
    ])
  }

  public var _eq: GraphQLNullable<String> {
    get { __data["_eq"] }
    set { __data["_eq"] = newValue }
  }

  public var _gt: GraphQLNullable<String> {
    get { __data["_gt"] }
    set { __data["_gt"] = newValue }
  }

  public var _gte: GraphQLNullable<String> {
    get { __data["_gte"] }
    set { __data["_gte"] = newValue }
  }

  /// does the column match the given case-insensitive pattern
  public var _ilike: GraphQLNullable<String> {
    get { __data["_ilike"] }
    set { __data["_ilike"] = newValue }
  }

  public var _in: GraphQLNullable<[String]> {
    get { __data["_in"] }
    set { __data["_in"] = newValue }
  }

  /// does the column match the given POSIX regular expression, case insensitive
  public var _iregex: GraphQLNullable<String> {
    get { __data["_iregex"] }
    set { __data["_iregex"] = newValue }
  }

  public var _isNull: GraphQLNullable<Bool> {
    get { __data["_is_null"] }
    set { __data["_is_null"] = newValue }
  }

  /// does the column match the given pattern
  public var _like: GraphQLNullable<String> {
    get { __data["_like"] }
    set { __data["_like"] = newValue }
  }

  public var _lt: GraphQLNullable<String> {
    get { __data["_lt"] }
    set { __data["_lt"] = newValue }
  }

  public var _lte: GraphQLNullable<String> {
    get { __data["_lte"] }
    set { __data["_lte"] = newValue }
  }

  public var _neq: GraphQLNullable<String> {
    get { __data["_neq"] }
    set { __data["_neq"] = newValue }
  }

  /// does the column NOT match the given case-insensitive pattern
  public var _nilike: GraphQLNullable<String> {
    get { __data["_nilike"] }
    set { __data["_nilike"] = newValue }
  }

  public var _nin: GraphQLNullable<[String]> {
    get { __data["_nin"] }
    set { __data["_nin"] = newValue }
  }

  /// does the column NOT match the given POSIX regular expression, case insensitive
  public var _niregex: GraphQLNullable<String> {
    get { __data["_niregex"] }
    set { __data["_niregex"] = newValue }
  }

  /// does the column NOT match the given pattern
  public var _nlike: GraphQLNullable<String> {
    get { __data["_nlike"] }
    set { __data["_nlike"] = newValue }
  }

  /// does the column NOT match the given POSIX regular expression, case sensitive
  public var _nregex: GraphQLNullable<String> {
    get { __data["_nregex"] }
    set { __data["_nregex"] = newValue }
  }

  /// does the column NOT match the given SQL regular expression
  public var _nsimilar: GraphQLNullable<String> {
    get { __data["_nsimilar"] }
    set { __data["_nsimilar"] = newValue }
  }

  /// does the column match the given POSIX regular expression, case sensitive
  public var _regex: GraphQLNullable<String> {
    get { __data["_regex"] }
    set { __data["_regex"] = newValue }
  }

  /// does the column match the given SQL regular expression
  public var _similar: GraphQLNullable<String> {
    get { __data["_similar"] }
    set { __data["_similar"] = newValue }
  }
}
