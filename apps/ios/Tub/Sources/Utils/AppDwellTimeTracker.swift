//
//  AppDwellTimeTracker.swift
//  Tub
//
//  Created by Nabeel Sheikh on 11/13/24.
//

import Foundation

class AppDwellTimeTracker: ObservableObject {
    static let shared = AppDwellTimeTracker()
    
    private var startTime: Date? {
        get {
            UserDefaults.standard.object(forKey: "app_start_time") as? Date
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "app_start_time")
            } else {
                UserDefaults.standard.removeObject(forKey: "app_start_time")
            }
        }
    }
    
    func startTracking() {
        if startTime == nil {
            startTime = Date()
            print("📱 App entered foreground")
        }
    }
    
    func endTracking() {
        guard let start = startTime else { return }
        let dwellTimeMs = Int(Date().timeIntervalSince(start) * 1000)
        
        Task {
            try? await Network.shared.recordClientEvent(
                event: Network.ClientEvent(
                    eventName: "app_dwell_time",
                    source: "app",
                    metadata: [
                        ["dwell_time_ms": dwellTimeMs]
                    ]
                )
            )
            print("✅ Recorded app dwell time: \(dwellTimeMs)ms")
        }
        
        startTime = nil
        print("📱 App session ended")
    }
}
