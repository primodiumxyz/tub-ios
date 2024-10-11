// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class RegisterManyNewTokensMutation: GraphQLMutation {
  public static let operationName: String = "RegisterManyNewTokens"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation RegisterManyNewTokens($objects: [token_insert_input!]!) { insert_token( objects: $objects on_conflict: { constraint: token_mint_key, update_columns: [] } ) { __typename affected_rows } }"#
    ))

  public var objects: [Token_insert_input]

  public init(objects: [Token_insert_input]) {
    self.objects = objects
  }

  public var __variables: Variables? { ["objects": objects] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_token", Insert_token?.self, arguments: [
        "objects": .variable("objects"),
        "on_conflict": [
          "constraint": "token_mint_key",
          "update_columns": []
        ]
      ]),
    ] }

    /// insert data into the table: "token"
    public var insert_token: Insert_token? { __data["insert_token"] }

    /// Insert_token
    ///
    /// Parent Type: `Token_mutation_response`
    public struct Insert_token: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_mutation_response }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("affected_rows", Int.self),
      ] }

      /// number of rows affected by the mutation
      public var affected_rows: Int { __data["affected_rows"] }
    }
  }
}
