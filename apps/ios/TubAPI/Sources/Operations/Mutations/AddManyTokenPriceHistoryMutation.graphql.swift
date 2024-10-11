// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class AddManyTokenPriceHistoryMutation: GraphQLMutation {
  public static let operationName: String = "AddManyTokenPriceHistory"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AddManyTokenPriceHistory($objects: [token_price_history_insert_input!]!) { insert_token_price_history(objects: $objects) { __typename returning { __typename id } } }"#
    ))

  public var objects: [Token_price_history_insert_input]

  public init(objects: [Token_price_history_insert_input]) {
    self.objects = objects
  }

  public var __variables: Variables? { ["objects": objects] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_token_price_history", Insert_token_price_history?.self, arguments: ["objects": .variable("objects")]),
    ] }

    /// insert data into the table: "token_price_history"
    public var insert_token_price_history: Insert_token_price_history? { __data["insert_token_price_history"] }

    /// Insert_token_price_history
    ///
    /// Parent Type: `Token_price_history_mutation_response`
    public struct Insert_token_price_history: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token_price_history_mutation_response }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("returning", [Returning].self),
      ] }

      /// data from the rows affected by the mutation
      public var returning: [Returning] { __data["returning"] }

      /// Insert_token_price_history.Returning
      ///
      /// Parent Type: `Token_price_history`
      public struct Returning: TubAPI.SelectionSet {
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
}
