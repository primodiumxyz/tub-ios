// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetFilterTokensQuery: GraphQLQuery {
    public static let operationName: String = "GetFilterTokens"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
        definition: .init(
            #"query GetFilterTokens($rankingAttribute: TokenRankingAttribute = volume1, $limit: Int = 50) { filterTokens( filters: { exchangeId: ["6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P:1399811149"] trendingIgnored: false potentialScam: false } rankings: { attribute: $rankingAttribute, direction: DESC } limit: $limit ) { __typename results { __typename token { __typename address info { __typename name symbol description imageLargeUrl imageSmallUrl imageThumbUrl } socialLinks { __typename discord instagram telegram twitter website } } priceUSD liquidity marketCap volume1 pair { __typename id } } } }"#
        )
    )

    public var rankingAttribute: GraphQLNullable<GraphQLEnum<TokenRankingAttribute>>
    public var limit: GraphQLNullable<Int>

    public init(
        rankingAttribute: GraphQLNullable<GraphQLEnum<TokenRankingAttribute>> = .init(.volume1),
        limit: GraphQLNullable<Int> = 15
    ) {
        self.rankingAttribute = rankingAttribute
        self.limit = limit
    }

    public var __variables: Variables? {
        [
            "rankingAttribute": rankingAttribute,
            "limit": limit,
        ]
    }

    public struct Data: CodexAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Query }
        public static var __selections: [ApolloAPI.Selection] {
            [
                .field(
                    "filterTokens",
                    FilterTokens?.self,
                    arguments: [
                        "filters": [
                            "exchangeId": ["6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P:1399811149"],
                            "trendingIgnored": false,
                            "potentialScam": false,
                        ],
                        "rankings": [
                            "attribute": .variable("rankingAttribute"),
                            "direction": "DESC",
                        ],
                        "limit": .variable("limit"),
                    ]
                )
            ]
        }

        /// Returns a list of tokens based on a variety of filters.
        public var filterTokens: FilterTokens? { __data["filterTokens"] }

        /// FilterTokens
        ///
        /// Parent Type: `TokenFilterConnection`
        public struct FilterTokens: CodexAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.TokenFilterConnection }
            public static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("results", [Result?]?.self),
                ]
            }

            /// The list of tokens matching the filter parameters.
            public var results: [Result?]? { __data["results"] }

            /// FilterTokens.Result
            ///
            /// Parent Type: `TokenFilterResult`
            public struct Result: CodexAPI.SelectionSet {
                public let __data: DataDict
                public init(_dataDict: DataDict) { __data = _dataDict }

                public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.TokenFilterResult }
                public static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("token", Token?.self),
                        .field("priceUSD", String?.self),
                        .field("liquidity", String?.self),
                        .field("marketCap", String?.self),
                        .field("volume1", String?.self),
                        .field("pair", Pair?.self),
                    ]
                }

                /// Metadata for the token.
                public var token: Token? { __data["token"] }
                /// The token price in USD.
                public var priceUSD: String? { __data["priceUSD"] }
                /// Amount of liquidity in the token's top pair.
                public var liquidity: String? { __data["liquidity"] }
                /// The fully diluted market cap. For circulating market cap multiply `token { info { circulatingSupply } }` by `priceUSD`.
                public var marketCap: String? { __data["marketCap"] }
                /// The trade volume in USD in the past hour.
                public var volume1: String? { __data["volume1"] }
                /// Metadata for the token's top pair.
                public var pair: Pair? { __data["pair"] }

                /// FilterTokens.Result.Token
                ///
                /// Parent Type: `EnhancedToken`
                public struct Token: CodexAPI.SelectionSet {
                    public let __data: DataDict
                    public init(_dataDict: DataDict) { __data = _dataDict }

                    public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.EnhancedToken }
                    public static var __selections: [ApolloAPI.Selection] {
                        [
                            .field("__typename", String.self),
                            .field("address", String.self),
                            .field("info", Info?.self),
                            .field("socialLinks", SocialLinks?.self),
                        ]
                    }

                    /// The contract address of the token.
                    public var address: String { __data["address"] }
                    /// More metadata about the token.
                    public var info: Info? { __data["info"] }
                    /// Community gathered links for the socials of this token.
                    public var socialLinks: SocialLinks? { __data["socialLinks"] }

                    /// FilterTokens.Result.Token.Info
                    ///
                    /// Parent Type: `TokenInfo`
                    public struct Info: CodexAPI.SelectionSet {
                        public let __data: DataDict
                        public init(_dataDict: DataDict) { __data = _dataDict }

                        public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.TokenInfo }
                        public static var __selections: [ApolloAPI.Selection] {
                            [
                                .field("__typename", String.self),
                                .field("name", String?.self),
                                .field("symbol", String.self),
                                .field("description", String?.self),
                                .field("imageLargeUrl", String?.self),
                                .field("imageSmallUrl", String?.self),
                                .field("imageThumbUrl", String?.self),
                            ]
                        }

                        /// The token name. For example, `ApeCoin`.
                        public var name: String? { __data["name"] }
                        /// The token symbol. For example, `APE`.
                        public var symbol: String { __data["symbol"] }
                        /// A description of the token.
                        public var description: String? { __data["description"] }
                        /// The large token logo URL.
                        public var imageLargeUrl: String? { __data["imageLargeUrl"] }
                        /// The small token logo URL.
                        public var imageSmallUrl: String? { __data["imageSmallUrl"] }
                        /// The thumbnail token logo URL.
                        public var imageThumbUrl: String? { __data["imageThumbUrl"] }
                    }

                    /// FilterTokens.Result.Token.SocialLinks
                    ///
                    /// Parent Type: `SocialLinks`
                    public struct SocialLinks: CodexAPI.SelectionSet {
                        public let __data: DataDict
                        public init(_dataDict: DataDict) { __data = _dataDict }

                        public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.SocialLinks }
                        public static var __selections: [ApolloAPI.Selection] {
                            [
                                .field("__typename", String.self),
                                .field("discord", String?.self),
                                .field("instagram", String?.self),
                                .field("telegram", String?.self),
                                .field("twitter", String?.self),
                                .field("website", String?.self),
                            ]
                        }

                        public var discord: String? { __data["discord"] }
                        public var instagram: String? { __data["instagram"] }
                        public var telegram: String? { __data["telegram"] }
                        public var twitter: String? { __data["twitter"] }
                        public var website: String? { __data["website"] }
                    }
                }

                /// FilterTokens.Result.Pair
                ///
                /// Parent Type: `Pair`
                public struct Pair: CodexAPI.SelectionSet {
                    public let __data: DataDict
                    public init(_dataDict: DataDict) { __data = _dataDict }

                    public static var __parentType: any ApolloAPI.ParentType { CodexAPI.Objects.Pair }
                    public static var __selections: [ApolloAPI.Selection] {
                        [
                            .field("__typename", String.self),
                            .field("id", String.self),
                        ]
                    }

                    /// The ID for the pair (`address:networkId`).
                    public var id: String { __data["id"] }
                }
            }
        }
    }
}
