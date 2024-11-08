// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SubLatestMockTokensSubscription: GraphQLSubscription {
  public static let operationName: String = "SubLatestMockTokens"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"subscription SubLatestMockTokens($limit: Int = 10) { token( where: { mint: { _is_null: true } } order_by: { updated_at: desc } limit: $limit ) { __typename id symbol supply name uri updated_at } }"#
    ))

  public var limit: GraphQLNullable<Int>

  public init(limit: GraphQLNullable<Int> = 10) {
    self.limit = limit
  }

  public var __variables: Variables? { ["limit": limit] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Subscription_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("token", [Token].self, arguments: [
        "where": ["mint": ["_is_null": true]],
        "order_by": ["updated_at": "desc"],
        "limit": .variable("limit")
      ]),
    ] }

    /// fetch data from the table: "token"
    public var token: [Token] { __data["token"] }

    /// Token
    ///
    /// Parent Type: `Token`
    public struct Token: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
        .field("symbol", String?.self),
        .field("supply", TubAPI.Numeric?.self),
        .field("name", String?.self),
        .field("uri", String?.self),
        .field("updated_at", TubAPI.Timestamptz.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
      public var symbol: String? { __data["symbol"] }
      public var supply: TubAPI.Numeric? { __data["supply"] }
      public var name: String? { __data["name"] }
      public var uri: String? { __data["uri"] }
      public var updated_at: TubAPI.Timestamptz { __data["updated_at"] }
    }
  }
}
