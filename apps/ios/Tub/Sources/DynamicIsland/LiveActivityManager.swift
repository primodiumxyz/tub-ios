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
    
    var isActivityActive: Bool {
        activity != nil
    }
    
    func startTrackingPurchase(tokenName: String, symbol: String, imageUrl: String, purchasePrice: Double) throws {
        stopActivity()
        
        let attributes = TubActivityAttributes(
            name: tokenName,
            symbol: symbol
        )
        let contentState = TubActivityAttributes.ContentState(
            value: 0.0,
            trend: "up",
            timestamp: Date(),
            currentPrice: purchasePrice
        )
        
        activity = try Activity<TubActivityAttributes>.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil)
        )
        print("Started tracking purchase: \(String(describing: activity?.id))")
    }
    
    func updatePriceChange(currentPrice: Double, gainsPercentage: Double) {
        Task {
            let formattedPercentage = String(format: "%.2f", abs(gainsPercentage))
            let contentState = TubActivityAttributes.ContentState(
                value: gainsPercentage,
                trend: gainsPercentage >= 0 ? "up" : "down",
                timestamp: Date(),
                currentPrice: currentPrice
            )
            print("Updating gains: \(formattedPercentage)%")
            await activity?.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    func stopActivity() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
            activity = nil
        }
    }
}
