//
//  Constants.swift
//  Tub
//
//  Created by polarzero on 07/11/2024.
//

import Foundation
import TubAPI
import Apollo

// Check the installation source of the app and always use remote if an external source (testFlight, appStore)

enum InstallationSource {
    case testFlight
    case appStore
    case xcode
    case invalid
}

let USDC_DECIMALS = 1e6
let SOL_DECIMALS = 1e9

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
private let graphqlUrlHost: String = "tub-graphql.primodium.ai"

// We use a compiler directive so the condition is only run once, during compilation, instead of on every import
public let graphqlHttpUrl: String = "https://\(graphqlUrlHost)/v1/graphql"

public let graphqlWsUrl: String = "wss://\(graphqlUrlHost)/v1/graphql"

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

// Filtering
public let HOT_TOKENS_INTERVAL: Interval = "30m" // main interval to aggregate and sort by volume
public let FILTERING_INTERVAL: Interval = "60s" // additional interval for filtering (min trades/volume)
public let FILTERING_MIN_TRADES: Numeric = 3 // minimum amount of trades during the above interval to be included
public let FILTERING_MIN_VOLUME_USD: Numeric = 0 // minimum volume during the above interval to be included

// Charts
public let CHART_INTERVAL: Double = 60 * 2  // live 2m
public let CANDLES_INTERVAL: Double = 60 * 30  // candles 30m
public let PRICE_UPDATE_INTERVAL: Double = 0.5  // Update price every half second
public let MAX_NUM_PRICES_TO_KEEP: Int = 100

public let WSOL_ADDRESS: String = "So11111111111111111111111111111111111111112"
public let USDC_MINT: String = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
public let TOKEN_PROGRAM_ID: String = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"

enum TubError: LocalizedError {
    case somethingWentWrong(reason: String)
    case networkFailure
    case graphQLError(errors: [GraphQLError])
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
        case .graphQLError(let errors):
            return "Database error"
        case .invalidInput(let reason):
            return "Invalid input \(reason)"
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

// Layout constants for spacing and sizing
enum Layout {
    enum Spacing {
        static let tiny = 0.01  // 1%
        static let xs = 0.015  // 1.5%
        static let sm = 0.035  // 3.5%
        static let md = 0.05  // 5%
        static let lg = 0.08  // 8%
        static let xl = 0.1  // 10%
    }

    enum Size {
        static let quarter = 0.25  // 25%
        static let third = 0.33  // 33%
        static let half = 0.5  // 50%
        static let twoThirds = 0.66  // 66%
        static let threeQuarters = 0.75  // 75%
        static let full = 1.0  // 100%
    }

    // Fixed dimensions
    enum Fixed {
        static let buttonHeight: CGFloat = 50
        static let smallButtonHeight: CGFloat = 40
        static let cornerRadius: CGFloat = 30
        static let borderWidth: CGFloat = 0.5
    }
}

