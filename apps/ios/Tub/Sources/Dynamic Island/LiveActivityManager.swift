//
//  LiveActivityManager.swift
//  Tub
//
//  Created by yixintan on 12/12/24.
//

import ActivityKit
import SwiftUI

@Observable class LiveActivityManager {
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
            activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            print("Started live activity: \(String(describing: activity?.id))")
        } catch {
            print("Error starting live activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(newValue: Double, trend: String) {
        Task {
            let updatedContentState = TubActivityAttributes.ContentState(
                value: newValue,
                trend: trend,
                timestamp: Date()
            )
            
            await activity?.update(using: updatedContentState)
        }
    }
    
    func stopActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
            activity = nil
        }
    }
}
