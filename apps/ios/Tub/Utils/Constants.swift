//
//  Constants.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/10/28.
//

import Foundation

// If on a physical device, check if ngrok environment variable exists and use if it does. Otherwise, default to the remote resources.
// If on a simulator, use the localhost URLs.

// GraphQL URLs
// Accessing environment variables happens at runtime, so cannot use a compiler directive conditional for graphqlUrlHost
// (See the next conditional, graphqlHttpUrl, for a compiler directive example.)
private let graphqlUrlHost: String = {
    if let ngrokUrl = ProcessInfo.processInfo.environment["NGROK_GRAPHQL_URL_HOST"] {
        return ngrokUrl
    } else {
        return "tub-graphql.primodium.ai"
    }
}()

// We use a compiler directive so the condition is only run once, during compilation, instead of on every import
public let graphqlHttpUrl: String = {
    #if targetEnvironment(simulator)
        return "http://localhost:8080/v1/graphql"
    #else
        return "https://\(graphqlUrlHost)/v1/graphql"
    #endif
}()

public let graphqlWsUrl: String = {
    #if targetEnvironment(simulator)
        return "ws://localhost:8080/v1/graphql"
    #else
        return "wss://\(graphqlUrlHost)/v1/graphql"
    #endif
}()

// Server URLs
private let serverUrlHost: String = {
    if let ngrokUrl = ProcessInfo.processInfo.environment["NGROK_SERVER_URL_HOST"] {
        return ngrokUrl
    } else {
        return "tub-server.primodium.ai"
    }
}()

public let serverBaseUrl: String = {
    #if targetEnvironment(simulator)
        return "http://localhost:8888/trpc"
    #else
        return "https://\(serverUrlHost)/trpc"
    #endif
}()
