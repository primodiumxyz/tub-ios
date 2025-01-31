// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class RefreshTokenRollingStats30MinMutation: GraphQLMutation {
  public static let operationName: String = "RefreshTokenRollingStats30Min"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation RefreshTokenRollingStats30Min { api_refresh_token_rolling_stats_30min { __typename id success } }"#
    ))

  public init() {}

  public struct Data: TubAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Mutation_root }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("api_refresh_token_rolling_stats_30min", Api_refresh_token_rolling_stats_30min?.self),
    ] }

    /// execute VOLATILE function "api.refresh_token_rolling_stats_30min" which returns "api.refresh_history"
    public var api_refresh_token_rolling_stats_30min: Api_refresh_token_rolling_stats_30min? { __data["api_refresh_token_rolling_stats_30min"] }

    /// Api_refresh_token_rolling_stats_30min
    ///
    /// Parent Type: `Api_refresh_history`
    public struct Api_refresh_token_rolling_stats_30min: TubAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { TubAPI.Objects.Api_refresh_history }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", TubAPI.Uuid.self),
        .field("success", Bool.self),
      ] }

      public var id: TubAPI.Uuid { __data["id"] }
      public var success: Bool { __data["success"] }
    }
  }
}
