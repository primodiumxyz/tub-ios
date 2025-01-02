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
            symbol: symbol,
            imageUrl: imageUrl
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
        
        // Start background updates
        startBackgroundUpdates(purchasePrice: purchasePrice)
    }
    
    private func startBackgroundUpdates(purchasePrice: Double) {
        backgroundTask = Task {
            while true {
                // Generate random change between -1% and +1% of purchase price
                let randomChange = purchasePrice * Double.random(in: -0.01...0.01)
                let currentPrice = purchasePrice + randomChange
                updatePriceChange(currentPrice: currentPrice, purchasePrice: purchasePrice)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
    
    func updatePriceChange(currentPrice: Double, purchasePrice: Double) {
        let percentageChange = ((currentPrice - purchasePrice) / purchasePrice) * 100
        
        Task {
            do {
                let contentState = TubActivityAttributes.ContentState(
                    value: percentageChange,
                    trend: percentageChange >= 0 ? "up" : "down",
                    timestamp: Date(),
                    currentPrice: currentPrice
                )
                print("Updating price change: \(percentageChange)%")
                try await activity?.update(.init(state: contentState, staleDate: nil))
            } catch {
                print("Error updating activity: \(error.localizedDescription)")
            }
        }
    }
    
    func stopActivity() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
            activity = nil
        }
    }
}
