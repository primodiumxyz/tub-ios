//
//  LiveActivityManager.swift
//  Tub
//
//  Created by yixintan on 12/12/24.
//

import ActivityKit
import SwiftUI
import os.log

/**
 * This class is responsible for managing the live activity for a token.
 * It is used to start, stop, and update it.
*/
@Observable class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    private var activity: Activity<TubActivityAttributes>?
    private var backgroundTask: Task<Void, Never>?
    var deviceToken: String?
    
    var isActivityActive: Bool {
        activity != nil
    }
    
    func startLiveActivity(mint: String, tokenName: String, symbol: String, purchasePriceUsd: Double, buyAmountUsdc: Int) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Logger().log("activities not enabled, skipping live activity")
            return
        }
        
        try await stopLiveActivity()
        let attributes = TubActivityAttributes(
            tokenMint: mint,
            name: tokenName,
            symbol: symbol,
            initialPriceUsd: purchasePriceUsd,
            buyAmountUsdc: buyAmountUsdc
        )
        let contentState = TubActivityAttributes.ContentState(
            currentPriceUsd: purchasePriceUsd,
            timestamp: Date.now.timeIntervalSince1970
        )
        
        let activity = try Activity<TubActivityAttributes>.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil),
            pushType: .token
        )

        
        Task {
            for await pushToken in activity.pushTokenUpdates {
                let pushTokenString = pushToken.reduce("") {
                    $0 + String(format: "%02x", $1)
                }
                
                guard let deviceToken else { return }
                
                try await Network.shared.startLiveActivity(tokenId: mint, tokenPriceUsd: String(purchasePriceUsd), deviceToken: deviceToken, pushToken: pushTokenString)
                
                
            }
        }

        self.activity = activity
    }

   func stopLiveActivity() async throws {
        await activity?.end(nil, dismissalPolicy: .immediate)
        try await Network.shared.stopLiveActivity()
        activity = nil
    }
    
    func updatePriceChange(currentPriceUsd: Double, gainsPercentage: Double) {
        Task {
            let formattedPercentage = String(format: "%.2f", abs(gainsPercentage))
            let contentState = TubActivityAttributes.ContentState(
               currentPriceUsd: currentPriceUsd,
               timestamp: Date().timeIntervalSince1970
            )
            await activity?.update(.init(state: contentState, staleDate: nil))
        }
    }
    
}
