// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

/// input type for inserting data into table "account_transaction"
public struct Account_transaction_insert_input: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    account: GraphQLNullable<Uuid> = nil,
    accountData: GraphQLNullable<Account_obj_rel_insert_input> = nil,
    amount: GraphQLNullable<Numeric> = nil,
    createdAt: GraphQLNullable<Timestamptz> = nil,
    id: GraphQLNullable<Uuid> = nil,
    tokenTransactions: GraphQLNullable<Token_transaction_arr_rel_insert_input> = nil
  ) {
    __data = InputDict([
      "account": account,
      "account_data": accountData,
      "amount": amount,
      "created_at": createdAt,
      "id": id,
      "token_transactions": tokenTransactions
    ])
  }

  public var account: GraphQLNullable<Uuid> {
    get { __data["account"] }
    set { __data["account"] = newValue }
  }

  public var accountData: GraphQLNullable<Account_obj_rel_insert_input> {
    get { __data["account_data"] }
    set { __data["account_data"] = newValue }
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
}
