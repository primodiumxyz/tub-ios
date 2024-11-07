// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SellTokenMutation: GraphQLMutation {
  public static let operationName: String = "SellToken"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation SellToken($wallet: String!, $token: uuid!, $amount: numeric!, $override_token_price: numeric) { sell_token( args: { user_wallet: $wallet token_id: $token amount_to_sell: $amount token_cost: $override_token_price } ) { __typename id } }"#
    ))

  public var wallet: String
  public var token: Uuid
  public var amount: Numeric
  public var override_token_price: GraphQLNullable<Numeric>

  public init(
    wallet: String,
    token: Uuid,
    amount: Numeric,
    override_token_price: GraphQLNullable<Numeric>
  ) {
    self.wallet = wallet
    self.token = token
    self.amount = amount
    self.override_token_price = override_token_price
  }

  public var __variables: Variables? { [
    "wallet": wallet,
    "token": token,
    "amount": amount,
    "override_token_price": override_token_price
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("sell_token", Sell_token?.self, arguments: ["args": [
        "user_wallet": .variable("wallet"),
        "token_id": .variable("token"),
        "amount_to_sell": .variable("amount"),
        "token_cost": .variable("override_token_price")
      ]]),
    ] }

    /// execute VOLATILE function "sell_token" which returns "token_transaction"
    public var sell_token: Sell_token? { __data["sell_token"] }

    /// Sell_token
    ///
    /// Parent Type: `Token_transaction`
    public struct Sell_token: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_transaction }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
