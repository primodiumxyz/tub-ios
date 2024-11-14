//
//  Constants.swift
//  Tub
//
//  Created by polarzero on 07/11/2024.
//

import Foundation
import TubAPI

// Check the installation source of the app and always use remote if an external source (testFlight, appStore)

enum InstallationSource {
    case testFlight
    case appStore
    case xcode
    case invalid
}

private var installationSource: InstallationSource {
    if let receiptUrl = Bundle.main.appStoreReceiptURL {
        let path = receiptUrl.path
        
        if path.contains("sandboxReceipt") {
            return .testFlight
        } else if path.contains("StoreKit") {
            return .appStore
        } else {
            return .xcode
        }
    } else {
        return .invalid
    }
}

// If on a physical device, check if ngrok environment variable exists and use if it does. Otherwise, default to the remote resources.
// If on a simulator, use the localhost URLs.

// GraphQL URLs
// Accessing environment variables happens at runtime, so cannot use a compiler directive conditional for graphqlUrlHost
// (See the next conditional, graphqlHttpUrl, for a compiler directive example.)
private let graphqlUrlHost: String = {
    if installationSource == .appStore || installationSource == .testFlight {
        return "tub-graphql.primodium.ai"
    } else if let ngrokUrl = ProcessInfo.processInfo.environment["NGROK_GRAPHQL_URL_HOST"] {
        return ngrokUrl
    } else {
        // Use remote for testing
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
   if installationSource == .appStore || installationSource == .testFlight {
       return "tub-server.primodium.ai"
   }
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

// Codex
public let RESOLUTION: String = "60" // base top tokens on 1 hour resolution
public let NETWORK_FILTER: Int = 1399811149

// Filtered tokens and chart
public let FILTER_INTERVAL: Double = 30 * 60
public let MIN_TRADES: Int = 0
public let MIN_VOLUME: Int = 0
public let MINT_BURNT: Bool = true
public let FREEZE_BURNT: Bool = true
    
public let CHART_INTERVAL: Double = 120
public let CHART_INTERVAL_MIN_TRADES: Int = 15
