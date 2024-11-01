// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting data into table "wallet_transaction"
public struct Wallet_transaction_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    amount: GraphQLNullable<Numeric> = nil,
    createdAt: GraphQLNullable<Timestamptz> = nil,
    id: GraphQLNullable<Uuid> = nil,
    tokenTransactions: GraphQLNullable<Token_transaction_arr_rel_insert_input> = nil,
    wallet: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "amount": amount,
      "created_at": createdAt,
      "id": id,
      "token_transactions": tokenTransactions,
      "wallet": wallet
    ])
  }

  public var amount: GraphQLNullable<Numeric> {
    get { __data["amount"] }
    set { __data["amount"] = newValue }
  }

  public var createdAt: GraphQLNullable<Timestamptz> {
    get { __data["created_at"] }
    set { __data["created_at"] = newValue }
  }

  public var id: GraphQLNullable<Uuid> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var tokenTransactions: GraphQLNullable<Token_transaction_arr_rel_insert_input> {
    get { __data["token_transactions"] }
    set { __data["token_transactions"] = newValue }
  }

  public var wallet: GraphQLNullable<String> {
    get { __data["wallet"] }
    set { __data["wallet"] = newValue }
  }
}
