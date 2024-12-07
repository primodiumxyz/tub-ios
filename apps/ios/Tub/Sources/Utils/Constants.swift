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
        }
        else if path.contains("StoreKit") {
            return .appStore
        }
        else {
            return .xcode
        }
    }
    else {
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
    }
    else if let ngrokUrl = ProcessInfo.processInfo.environment["NGROK_GRAPHQL_URL_HOST"] {
        return ngrokUrl
    }
    else {
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
    }
    else {
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

public let solanaUrl: String = {
    return "https://blue-hardworking-paper.solana-mainnet.quiknode.pro/4240df2ab8f252905cfef06e20240f563e84418d"
}()

public let NETWORK_FILTER: Int = 1_399_811_149  // Solana filter for Codex
public let CHART_INTERVAL: Double = 60 * 2  // live 2m
public let CANDLES_INTERVAL: Double = 60 * 30  // candles 30m
public let PRICE_UPDATE_INTERVAL: Double = 0.5  // Update price every half second
public let MAX_NUM_PRICES_TO_KEEP: Int = 100

public let WSOL_ADDRESS: String = "So11111111111111111111111111111111111111112"

enum TubError: LocalizedError {
    case somethingWentWrong(reason: String)
    case networkFailure
    case invalidInput(reason: String)
    case unknown
    case insufficientBalance
    case notLoggedIn
    case parsingError
    case actionInProgress(actionDescription: String)
    case actionFailed(failureDescription: String)
    case emptyTokenList
    case serverError(reason: String)

    var errorDescription: String? {
        switch self {
        case .somethingWentWrong(let reason):
            return "Something went wrong: \(reason)"
        case .insufficientBalance:
            return "Insufficient balance"
        case .notLoggedIn:
            return "Not logged in"
        case .networkFailure:
            return "Couldn't connect"
        case .invalidInput:
            return "Invalid input"
        case .parsingError:
            return "Parsing error"
        case .actionInProgress(let actionDescription):
            return "\(actionDescription) already in progress"
        case .actionFailed(let failureDescription):
            return "\(failureDescription)"
        case .emptyTokenList:
            return "No tokens found"
        case .serverError(let reason):
            return reason
        default:
            return "Unknown error"
        }
    }
}

enum Timespan: String, CaseIterable {
    case live = "LIVE"
    case candles = "30M"

    public var seconds: Double {
        switch self {
        case .live: return CHART_INTERVAL
        case .candles: return CANDLES_INTERVAL
        }
    }
}
