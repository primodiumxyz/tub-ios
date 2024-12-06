// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokensMetadataQuery: GraphQLQuery {
  public static let operationName: String = "GetTokensMetadata"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokensMetadata($tokens: [String!]!) { api_trade_history( where: { token_mint: { _in: $tokens } } order_by: [{ token_mint: asc }, { created_at: desc }] distinct_on: [token_mint] ) { __typename token_mint token_metadata } }"#
    ))

  public var tokens: [String]

  public init(tokens: [String]) {
    self.tokens = tokens
  }

  public var __variables: Variables? { ["tokens": tokens] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("api_trade_history", [Api_trade_history].self, arguments: [
        "where": ["token_mint": ["_in": .variable("tokens")]],
        "order_by": [["token_mint": "asc"], ["created_at": "desc"]],
        "distinct_on": ["token_mint"]
      ]),
    ] }

    /// fetch data from the table: "api.trade_history"
    public var api_trade_history: [Api_trade_history] { __data["api_trade_history"] }

    /// Api_trade_history
    ///
    /// Parent Type: `Api_trade_history`
    public struct Api_trade_history: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Api_trade_history }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token_mint", String.self),
        .field("token_metadata", TubAPI.Token_metadata_scalar.self),
      ] }

      public var token_mint: String { __data["token_mint"] }
      public var token_metadata: TubAPI.Token_metadata_scalar { __data["token_metadata"] }
    }
  }
}
