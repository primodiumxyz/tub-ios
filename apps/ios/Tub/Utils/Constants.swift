//
//  Constants.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/10/28.
//

import Foundation

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

// Replace the conditional graphqlHttpUrl with:
public let graphqlHttpUrl: String = "https://tub-graphql.primodium.ai/v1/graphql"

// Replace the conditional graphqlWsUrl with:
public let graphqlWsUrl: String = "wss://tub-graphql.primodium.ai/v1/graphql"

// Replace the conditional serverBaseUrl with:
public let serverBaseUrl: String = "https://tub-server.primodium.ai/trpc"

// Server URLs
private let serverUrlHost: String = {
    if installationSource == .appStore || installationSource == .testFlight {
        return "tub-server.primodium.ai"
    } else if let ngrokUrl = ProcessInfo.processInfo.environment["NGROK_SERVER_URL_HOST"] {
        return ngrokUrl
    } else {
        return "tub-server.primodium.ai"
    }
}()