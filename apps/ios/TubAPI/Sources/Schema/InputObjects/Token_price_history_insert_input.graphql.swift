// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting data into table "token_price_history"
public struct Token_price_history_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    createdAt: GraphQLNullable<Timestamptz> = nil,
    id: GraphQLNullable<Uuid> = nil,
    internalTokenTransactionRef: GraphQLNullable<Uuid> = nil,
    price: GraphQLNullable<Numeric> = nil,
    token: GraphQLNullable<Uuid> = nil,
    tokenRelationship: GraphQLNullable<Token_obj_rel_insert_input> = nil,
    tokenTransaction: GraphQLNullable<Token_transaction_obj_rel_insert_input> = nil
  ) {
    __data = InputDict([
      "created_at": createdAt,
      "id": id,
      "internal_token_transaction_ref": internalTokenTransactionRef,
      "price": price,
      "token": token,
      "token_relationship": tokenRelationship,
      "token_transaction": tokenTransaction
    ])
  }

  public var createdAt: GraphQLNullable<Timestamptz> {
    get { __data["created_at"] }
    set { __data["created_at"] = newValue }
  }

  public var id: GraphQLNullable<Uuid> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var internalTokenTransactionRef: GraphQLNullable<Uuid> {
    get { __data["internal_token_transaction_ref"] }
    set { __data["internal_token_transaction_ref"] = newValue }
  }

  public var price: GraphQLNullable<Numeric> {
    get { __data["price"] }
    set { __data["price"] = newValue }
  }

  public var token: GraphQLNullable<Uuid> {
    get { __data["token"] }
    set { __data["token"] = newValue }
  }

  public var tokenRelationship: GraphQLNullable<Token_obj_rel_insert_input> {
    get { __data["token_relationship"] }
    set { __data["token_relationship"] = newValue }
  }

  public var tokenTransaction: GraphQLNullable<Token_transaction_obj_rel_insert_input> {
    get { __data["token_transaction"] }
    set { __data["token_transaction"] = newValue }
  }
}
