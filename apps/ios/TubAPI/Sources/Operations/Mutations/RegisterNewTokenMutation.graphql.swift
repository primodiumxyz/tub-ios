// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class RegisterNewTokenMutation: GraphQLMutation {
  public static let operationName: String = "RegisterNewToken"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation RegisterNewToken($name: String!, $symbol: String!, $supply: numeric!, $uri: String) { insert_token_one( object: { name: $name, symbol: $symbol, uri: $uri, supply: $supply } ) { __typename id } }"#
    ))

  public var name: String
  public var symbol: String
  public var supply: Numeric
  public var uri: GraphQLNullable<String>

  public init(
    name: String,
    symbol: String,
    supply: Numeric,
    uri: GraphQLNullable<String>
  ) {
    self.name = name
    self.symbol = symbol
    self.supply = supply
    self.uri = uri
  }

  public var __variables: Variables? { [
    "name": name,
    "symbol": symbol,
    "supply": supply,
    "uri": uri
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_token_one", Insert_token_one?.self, arguments: ["object": [
        "name": .variable("name"),
        "symbol": .variable("symbol"),
        "uri": .variable("uri"),
        "supply": .variable("supply")
      ]]),
    ] }

    /// insert a single row into the table: "token"
    public var insert_token_one: Insert_token_one? { __data["insert_token_one"] }

    /// Insert_token_one
    ///
    /// Parent Type: `Token`
    public struct Insert_token_one: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Token }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
