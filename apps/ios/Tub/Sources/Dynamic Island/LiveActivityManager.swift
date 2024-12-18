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
    
    func startTrackingPurchase(tokenName: String, symbol: String, imageUrl: String, purchasePrice: Double) {
        stopActivity()
        
        let attributes = TubActivityAttributes(
            name: tokenName,
            symbol: symbol,
            imageUrl: imageUrl
        )
        let contentState = TubActivityAttributes.ContentState(
            value: 0.0,
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
            
            // Start background updates
            startBackgroundUpdates(purchasePrice: purchasePrice)
        } catch {
            print("Error starting purchase tracking: \(error.localizedDescription)")
        }
    }
    
    private func startBackgroundUpdates(purchasePrice: Double) {
        backgroundTask = Task {
            while true {
                let currentPrice = purchasePrice + Double.random(in: -0.01...0.01)
                updatePriceChange(currentPrice: currentPrice, purchasePrice: purchasePrice)
                try? await Task.sleep(for: .seconds(1))
            }
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
