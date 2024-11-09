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

// Replace the conditional graphqlHttpUrl with:
public let graphqlHttpUrl: String = "https://tub-graphql.primodium.ai/v1/graphql"

// Replace the conditional graphqlWsUrl with:
public let graphqlWsUrl: String = "wss://tub-graphql.primodium.ai/v1/graphql"

// Replace the conditional serverBaseUrl with:
public let serverBaseUrl: String = "https://tub-server.primodium.ai/trpc"


// Filtered tokens and chart
public let FILTER_INTERVAL: Interval = "30m"
public let MIN_TRADES: Int = 0
public let MIN_VOLUME: Int = 0
public let MINT_BURNT: Bool = true
public let FREEZE_BURNT: Bool = true
    
public let CHART_INTERVAL: Interval = "1m"
public let CHART_INTERVAL_MIN_TRADES: Int = 15
