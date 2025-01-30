// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class AddLoadingTimeMutation: GraphQLMutation {
  public static let operationName: String = "AddLoadingTime"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AddLoadingTime($identifier: String!, $time_elapsed_ms: numeric!, $attempt_number: Int!, $total_time_ms: numeric!, $average_time_ms: numeric!, $user_wallet: String!, $user_agent: String!, $source: String, $error_details: String, $build: String) { insert_loading_time_one( object: { identifier: $identifier time_elapsed_ms: $time_elapsed_ms attempt_number: $attempt_number total_time_ms: $total_time_ms average_time_ms: $average_time_ms user_wallet: $user_wallet user_agent: $user_agent source: $source error_details: $error_details build: $build } ) { __typename id } }"#
    ))

  public var identifier: String
  public var time_elapsed_ms: Numeric
  public var attempt_number: Int
  public var total_time_ms: Numeric
  public var average_time_ms: Numeric
  public var user_wallet: String
  public var user_agent: String
  public var source: GraphQLNullable<String>
  public var error_details: GraphQLNullable<String>
  public var build: GraphQLNullable<String>

  public init(
    identifier: String,
    time_elapsed_ms: Numeric,
    attempt_number: Int,
    total_time_ms: Numeric,
    average_time_ms: Numeric,
    user_wallet: String,
    user_agent: String,
    source: GraphQLNullable<String>,
    error_details: GraphQLNullable<String>,
    build: GraphQLNullable<String>
  ) {
    self.identifier = identifier
    self.time_elapsed_ms = time_elapsed_ms
    self.attempt_number = attempt_number
    self.total_time_ms = total_time_ms
    self.average_time_ms = average_time_ms
    self.user_wallet = user_wallet
    self.user_agent = user_agent
    self.source = source
    self.error_details = error_details
    self.build = build
  }

  public var __variables: Variables? { [
    "identifier": identifier,
    "time_elapsed_ms": time_elapsed_ms,
    "attempt_number": attempt_number,
    "total_time_ms": total_time_ms,
    "average_time_ms": average_time_ms,
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
      .field("insert_loading_time_one", Insert_loading_time_one?.self, arguments: ["object": [
        "identifier": .variable("identifier"),
        "time_elapsed_ms": .variable("time_elapsed_ms"),
        "attempt_number": .variable("attempt_number"),
        "total_time_ms": .variable("total_time_ms"),
        "average_time_ms": .variable("average_time_ms"),
        "user_wallet": .variable("user_wallet"),
        "user_agent": .variable("user_agent"),
        "source": .variable("source"),
        "error_details": .variable("error_details"),
        "build": .variable("build")
      ]]),
    ] }

    /// insert a single row into the table: "loading_time"
    public var insert_loading_time_one: Insert_loading_time_one? { __data["insert_loading_time_one"] }

    /// Insert_loading_time_one
    ///
    /// Parent Type: `Loading_time`
    public struct Insert_loading_time_one: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Loading_time }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
    }
  }
}
