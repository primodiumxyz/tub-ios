//
//  LiveActivityManager.swift
//  Tub
//
//  Created by yixintan on 12/12/24.
//

import ActivityKit
import SwiftUI

@Observable class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    private var activity: Activity<TubActivityAttributes>?
    private var backgroundTask: Task<Void, Never>?
    var deviceToken: String?
    
    var isActivityActive: Bool {
        activity != nil
    }
    
    func startTrackingPurchase(mint: String, tokenName: String, symbol: String, purchasePriceUsd: Double) async throws {
        try await stopActivity()
        
        let attributes = TubActivityAttributes(
            tokenMint: mint,
            name: tokenName,
            symbol: symbol,
            initialPriceUsd: purchasePriceUsd
        )
        let contentState = TubActivityAttributes.ContentState(
            currentPriceUsd: purchasePriceUsd,
            timestamp: Date.now
        )
        
        activity = try Activity<TubActivityAttributes>.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil)
        )

        
        if let deviceToken {
            try await Network.shared.startLiveActivity(
                tokenId: mint,
                tokenPriceUsd: String(purchasePriceUsd),
                deviceToken: deviceToken
            )
        }

        print("Started tracking purchase: \(String(describing: activity?.id))")
    }
    
    func updatePriceChange(currentPriceUsd: Double, gainsPercentage: Double) {
        Task {
            let formattedPercentage = String(format: "%.2f", abs(gainsPercentage))
            let contentState = TubActivityAttributes.ContentState(
                currentPriceUsd: currentPriceUsd,
                timestamp: Date()
            )
            print("Updating gains: \(formattedPercentage)%")
            await activity?.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    func stopActivity() async throws {
        try await Network.shared.stopLiveActivity()
            await activity?.end(nil, dismissalPolicy: .immediate)
            activity = nil
    }
}
