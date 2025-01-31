// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class AddAppDwellTimeMutation: GraphQLMutation {
  public static let operationName: String = "AddAppDwellTime"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AddAppDwellTime($dwell_time_ms: numeric!, $user_wallet: String!, $user_agent: String!, $source: String, $error_details: String, $build: String) { insert_app_dwell_time_one( object: { dwell_time_ms: $dwell_time_ms user_wallet: $user_wallet user_agent: $user_agent source: $source error_details: $error_details build: $build } ) { __typename id } }"#
    ))

  public var dwell_time_ms: Numeric
  public var user_wallet: String
  public var user_agent: String
  public var source: GraphQLNullable<String>
  public var error_details: GraphQLNullable<String>
  public var build: GraphQLNullable<String>

  public init(
    dwell_time_ms: Numeric,
    user_wallet: String,
    user_agent: String,
    source: GraphQLNullable<String>,
    error_details: GraphQLNullable<String>,
    build: GraphQLNullable<String>
  ) {
    self.dwell_time_ms = dwell_time_ms
    self.user_wallet = user_wallet
    self.user_agent = user_agent
    self.source = source
    self.error_details = error_details
    self.build = build
  }

  public var __variables: Variables? { [
    "dwell_time_ms": dwell_time_ms,
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
      .field("insert_app_dwell_time_one", Insert_app_dwell_time_one?.self, arguments: ["object": [
        "dwell_time_ms": .variable("dwell_time_ms"),
        "user_wallet": .variable("user_wallet"),
        "user_agent": .variable("user_agent"),
        "source": .variable("source"),
        "error_details": .variable("error_details"),
        "build": .variable("build")
      ]]),
    ] }

    /// insert a single row into the table: "app_dwell_time"
    public var insert_app_dwell_time_one: Insert_app_dwell_time_one? { __data["insert_app_dwell_time_one"] }

    /// Insert_app_dwell_time_one
    ///
    /// Parent Type: `App_dwell_time`
    public struct Insert_app_dwell_time_one: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.App_dwell_time }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
