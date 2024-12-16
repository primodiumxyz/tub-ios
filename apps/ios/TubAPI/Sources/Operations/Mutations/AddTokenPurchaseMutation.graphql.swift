// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class AddTokenPurchaseMutation: GraphQLMutation {
  public static let operationName: String = "AddTokenPurchase"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AddTokenPurchase($insert_token_purchase_one: token_purchase_insert_input!) { insert_token_purchase_one(object: $insert_token_purchase_one) { __typename id } }"#
    ))

  public var insert_token_purchase_one: Token_purchase_insert_input

  public init(insert_token_purchase_one: Token_purchase_insert_input) {
    self.insert_token_purchase_one = insert_token_purchase_one
  }

  public var __variables: Variables? { ["insert_token_purchase_one": insert_token_purchase_one] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_token_purchase_one", Insert_token_purchase_one?.self, arguments: ["object": .variable("insert_token_purchase_one")]),
    ] }

    /// insert a single row into the table: "token_purchase"
    public var insert_token_purchase_one: Insert_token_purchase_one? { __data["insert_token_purchase_one"] }

    /// Insert_token_purchase_one
    ///
    /// Parent Type: `Token_purchase`
    public struct Insert_token_purchase_one: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_purchase }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
