// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class AddTokenPurchaseMutation: GraphQLMutation {
  public static let operationName: String = "AddTokenPurchase"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AddTokenPurchase($token_mint: String!, $token_amount: numeric!, $token_price_usd: numeric!, $token_decimals: Int!, $user_wallet: String!, $user_agent: String!, $source: String, $error_details: String, $build: String) { insert_token_purchase_one( object: { token_mint: $token_mint token_amount: $token_amount token_price_usd: $token_price_usd token_decimals: $token_decimals user_wallet: $user_wallet user_agent: $user_agent source: $source error_details: $error_details build: $build } ) { __typename id } }"#
    ))

  public var token_mint: String
  public var token_amount: Numeric
  public var token_price_usd: Numeric
  public var token_decimals: Int
  public var user_wallet: String
  public var user_agent: String
  public var source: GraphQLNullable<String>
  public var error_details: GraphQLNullable<String>
  public var build: GraphQLNullable<String>

  public init(
    token_mint: String,
    token_amount: Numeric,
    token_price_usd: Numeric,
    token_decimals: Int,
    user_wallet: String,
    user_agent: String,
    source: GraphQLNullable<String>,
    error_details: GraphQLNullable<String>,
    build: GraphQLNullable<String>
  ) {
    self.token_mint = token_mint
    self.token_amount = token_amount
    self.token_price_usd = token_price_usd
    self.token_decimals = token_decimals
    self.user_wallet = user_wallet
    self.user_agent = user_agent
    self.source = source
    self.error_details = error_details
    self.build = build
  }

  public var __variables: Variables? { [
    "token_mint": token_mint,
    "token_amount": token_amount,
    "token_price_usd": token_price_usd,
    "token_decimals": token_decimals,
    "user_wallet": user_wallet,
    "user_agent": user_agent,
    "source": source,
    "error_details": error_details,
    "build": build
  ] }

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("insert_token_purchase_one", Insert_token_purchase_one?.self, arguments: ["object": [
        "token_mint": .variable("token_mint"),
        "token_amount": .variable("token_amount"),
        "token_price_usd": .variable("token_price_usd"),
        "token_decimals": .variable("token_decimals"),
        "user_wallet": .variable("user_wallet"),
        "user_agent": .variable("user_agent"),
        "source": .variable("source"),
        "error_details": .variable("error_details"),
        "build": .variable("build")
      ]]),
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
