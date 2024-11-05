// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting data into table "token_transaction"
public struct Token_transaction_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    amount: GraphQLNullable<Numeric> = nil,
    id: GraphQLNullable<Uuid> = nil,
    token: GraphQLNullable<Uuid> = nil,
    tokenData: GraphQLNullable<Token_obj_rel_insert_input> = nil,
    tokenPrice: GraphQLNullable<Token_price_history_obj_rel_insert_input> = nil,
    walletTransaction: GraphQLNullable<Uuid> = nil,
    walletTransactionData: GraphQLNullable<Wallet_transaction_obj_rel_insert_input> = nil
  ) {
    __data = InputDict([
      "amount": amount,
      "id": id,
      "token": token,
      "token_data": tokenData,
      "token_price": tokenPrice,
      "wallet_transaction": walletTransaction,
      "wallet_transaction_data": walletTransactionData
    ])
  }

  public var amount: GraphQLNullable<Numeric> {
    get { __data["amount"] }
    set { __data["amount"] = newValue }
  }

  public var id: GraphQLNullable<Uuid> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var token: GraphQLNullable<Uuid> {
    get { __data["token"] }
    set { __data["token"] = newValue }
  }

  public var tokenData: GraphQLNullable<Token_obj_rel_insert_input> {
    get { __data["token_data"] }
    set { __data["token_data"] = newValue }
  }

  public var tokenPrice: GraphQLNullable<Token_price_history_obj_rel_insert_input> {
    get { __data["token_price"] }
    set { __data["token_price"] = newValue }
  }

  public var walletTransaction: GraphQLNullable<Uuid> {
    get { __data["wallet_transaction"] }
    set { __data["wallet_transaction"] = newValue }
  }

  public var walletTransactionData: GraphQLNullable<Wallet_transaction_obj_rel_insert_input> {
    get { __data["wallet_transaction_data"] }
    set { __data["wallet_transaction_data"] = newValue }
  }
}
