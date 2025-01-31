// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class InsertTradeHistoryManyMutation: GraphQLMutation {
  public static let operationName: String = "InsertTradeHistoryMany"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation InsertTradeHistoryMany($trades: [api_trade_history_insert_input!]!) { insert_api_trade_history(objects: $trades) { __typename affected_rows } }"#
    ))

  public var trades: [Api_trade_history_insert_input]

  public init(trades: [Api_trade_history_insert_input]) {
    self.trades = trades
  }

  public var __variables: Variables? { ["trades": trades] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_api_trade_history", Insert_api_trade_history?.self, arguments: ["objects": .variable("trades")]),
    ] }

    /// insert data into the table: "api.trade_history"
    public var insert_api_trade_history: Insert_api_trade_history? { __data["insert_api_trade_history"] }

    /// Insert_api_trade_history
    ///
    /// Parent Type: `Api_trade_history_mutation_response`
    public struct Insert_api_trade_history: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Api_trade_history_mutation_response }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("affected_rows", Int.self),
      ] }

      /// number of rows affected by the mutation
      public var affected_rows: Int { __data["affected_rows"] }
    }
  }
}
