// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class AddTokenSaleMutation: GraphQLMutation {
  public static let operationName: String = "AddTokenSale"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AddTokenSale($insert_token_sale_one: token_sale_insert_input!) { insert_token_sale_one(object: $insert_token_sale_one) { __typename id } }"#
    ))

  public var insert_token_sale_one: Token_sale_insert_input

  public init(insert_token_sale_one: Token_sale_insert_input) {
    self.insert_token_sale_one = insert_token_sale_one
  }

  public var __variables: Variables? { ["insert_token_sale_one": insert_token_sale_one] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_token_sale_one", Insert_token_sale_one?.self, arguments: ["object": .variable("insert_token_sale_one")]),
    ] }

    /// insert a single row into the table: "token_sale"
    public var insert_token_sale_one: Insert_token_sale_one? { __data["insert_token_sale_one"] }

    /// Insert_token_sale_one
    ///
    /// Parent Type: `Token_sale`
    public struct Insert_token_sale_one: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_sale }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
