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
    
    func startActivity(name: String, symbol: String, initialValue: Double) {
        // End any existing activity
        stopActivity()
        
        let attributes = TubActivityAttributes(name: name, symbol: symbol)
        let contentState = TubActivityAttributes.ContentState(
            value: initialValue,
            trend: "up",
            timestamp: Date()
        )
        
        do {
            activity = try Activity<TubActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            print("Started live activity: \(String(describing: activity?.id))")
        } catch {
            print("Error starting live activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(newValue: Double, trend: Double) {
        Task {
            let contentState = TubActivityAttributes.ContentState(
                value: newValue,
                trend: trend > 0 ? "up" : "down",
                timestamp: Date()
            )
            print("Updating activity with new value: \(newValue)")
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
