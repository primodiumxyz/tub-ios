// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == CodexAPI.SchemaMetadata {}

public protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == CodexAPI.SchemaMetadata {}

public protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == CodexAPI.SchemaMetadata {}

public protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == CodexAPI.SchemaMetadata {}

public enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
        switch typename {
        case "AddTokenEventsOutput": return CodexAPI.Objects.AddTokenEventsOutput
        case "BarsResponse": return CodexAPI.Objects.BarsResponse
        case "CurrencyBarData": return CodexAPI.Objects.CurrencyBarData
        case "EnhancedToken": return CodexAPI.Objects.EnhancedToken
        case "Event": return CodexAPI.Objects.Event
        case "HoldersResponse": return CodexAPI.Objects.HoldersResponse
        case "IndividualBarData": return CodexAPI.Objects.IndividualBarData
        case "OnBarsUpdatedResponse": return CodexAPI.Objects.OnBarsUpdatedResponse
        case "Pair": return CodexAPI.Objects.Pair
        case "Price": return CodexAPI.Objects.Price
        case "Query": return CodexAPI.Objects.Query
        case "ResolutionBarData": return CodexAPI.Objects.ResolutionBarData
        case "SocialLinks": return CodexAPI.Objects.SocialLinks
        case "Subscription": return CodexAPI.Objects.Subscription
        case "TokenFilterConnection": return CodexAPI.Objects.TokenFilterConnection
        case "TokenFilterResult": return CodexAPI.Objects.TokenFilterResult
        case "TokenInfo": return CodexAPI.Objects.TokenInfo
        default: return nil
        }
    }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
