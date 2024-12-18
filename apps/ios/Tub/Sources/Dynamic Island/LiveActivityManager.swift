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
    
    var isActivityActive: Bool {
        activity != nil
    }
    
    func startTrackingPurchase(tokenName: String, symbol: String, imageUrl: String, purchasePrice: Double) {
        // End any existing activity
        stopActivity()
        
        let attributes = TubActivityAttributes(
            name: tokenName, 
            symbol: symbol,
            imageUrl: imageUrl
        )
        let contentState = TubActivityAttributes.ContentState(
            value: 0.0, // Initial percentage change
            trend: "up",
            timestamp: Date(),
            currentPrice: purchasePrice
        )
        
        do {
            activity = try Activity<TubActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            print("Started tracking purchase: \(String(describing: activity?.id))")
        } catch {
            print("Error starting purchase tracking: \(error.localizedDescription)")
        }
    }
    
    func updatePriceChange(currentPrice: Double, purchasePrice: Double) {
        let percentageChange = ((currentPrice - purchasePrice) / purchasePrice) * 100
        
        Task {
            let contentState = TubActivityAttributes.ContentState(
                value: percentageChange,
                trend: percentageChange >= 0 ? "up" : "down",
                timestamp: Date(),
                currentPrice: currentPrice
            )
            print("Updating price change: \(percentageChange)%")
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
