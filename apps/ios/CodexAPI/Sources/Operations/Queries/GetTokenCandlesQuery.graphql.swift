// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetTokenCandlesQuery: GraphQLQuery {
  public static let operationName: String = "GetTokenCandles"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetTokenCandles($from: Int!, $to: Int!, $symbol: String!, $resolution: String = "1") { getBars(from: $from, to: $to, symbol: $symbol, resolution: $resolution) { __typename o h l c v t } }"#
    ))

  public var from: Int
  public var to: Int
  public var symbol: String
  public var resolution: GraphQLNullable<String>

  public init(
    from: Int,
    to: Int,
    symbol: String,
    resolution: GraphQLNullable<String> = "1"
  ) {
    self.from = from
    self.to = to
    self.symbol = symbol
    self.resolution = resolution
  }

  public var __variables: Variables? { [
    "from": from,
    "to": to,
    "symbol": symbol,
    "resolution": resolution
  ] }

  public struct Data: CodexAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("getBars", GetBars?.self, arguments: [
        "from": .variable("from"),
        "to": .variable("to"),
        "symbol": .variable("symbol"),
        "resolution": .variable("resolution")
      ]),
    ] }

    /// Returns bar chart data to track price changes over time.
    public var getBars: GetBars? { __data["getBars"] }

    /// GetBars
    ///
    /// Parent Type: `BarsResponse`
    public struct GetBars: CodexAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.BarsResponse }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("o", [Double?].self),
        .field("h", [Double?].self),
        .field("l", [Double?].self),
        .field("c", [Double?].self),
        .field("v", [Int?].self),
        .field("t", [Int].self),
      ] }

      /// The opening price.
      public var o: [Double?] { __data["o"] }
      /// The high price.
      public var h: [Double?] { __data["h"] }
      /// The low price.
      public var l: [Double?] { __data["l"] }
      /// The closing price.
      public var c: [Double?] { __data["c"] }
      /// The volume.
      public var v: [Int?] { __data["v"] }
      /// The timestamp for the bar.
      public var t: [Int] { __data["t"] }
    }
  }
}
