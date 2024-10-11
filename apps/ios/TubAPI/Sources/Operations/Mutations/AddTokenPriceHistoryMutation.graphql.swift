// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class AddTokenPriceHistoryMutation: GraphQLMutation {
  public static let operationName: String = "AddTokenPriceHistory"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AddTokenPriceHistory($token: uuid!, $price: numeric!) { insert_token_price_history_one(object: { token: $token, price: $price }) { __typename id } }"#
    ))

  public var token: Uuid
  public var price: Numeric

  public init(
    token: Uuid,
    price: Numeric
  ) {
    self.token = token
    self.price = price
  }

  public var __variables: Variables? { [
    "token": token,
    "price": price
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_token_price_history_one", Insert_token_price_history_one?.self, arguments: ["object": [
        "token": .variable("token"),
        "price": .variable("price")
      ]]),
    ] }

    /// insert a single row into the table: "token_price_history"
    public var insert_token_price_history_one: Insert_token_price_history_one? { __data["insert_token_price_history_one"] }

    /// Insert_token_price_history_one
    ///
    /// Parent Type: `Token_price_history`
    public struct Insert_token_price_history_one: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_price_history }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
