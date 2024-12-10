// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenPricesSinceQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenPricesSince"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenPricesSince($token: String!, $since: timestamptz = "now()") { api_trade_history( where: { token_mint: { _eq: $token }, created_at: { _gte: $since } } order_by: { created_at: asc } ) { __typename token_price_usd created_at } }"#
    ))

  public var token: String
  public var since: GraphQLNullable<Timestamptz>

  public init(
    token: String,
    since: GraphQLNullable<Timestamptz> = "now()"
  ) {
    self.token = token
    self.since = since
  }

  public var __variables: Variables? { [
    "token": token,
    "since": since
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Query_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("api_trade_history", [Api_trade_history].self, arguments: [
        "where": [
          "token_mint": ["_eq": .variable("token")],
          "created_at": ["_gte": .variable("since")]
        ],
        "order_by": ["created_at": "asc"]
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
        .field("token_price_usd", TubAPI.Numeric.self),
        .field("created_at", TubAPI.Timestamptz.self),
      ] }

      public var token_price_usd: TubAPI.Numeric { __data["token_price_usd"] }
      public var created_at: TubAPI.Timestamptz { __data["created_at"] }
    }
  }
}
