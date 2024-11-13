//
//  LoadingTracker.swift
//  Tub
//
//  Created by polarzero on 09/11/2024.
//

import Foundation

class LoadingTracker: ObservableObject {
    static let shared = LoadingTracker()

    private struct LoadingMetrics {
        var startTime: Date?
        var totalTime: TimeInterval = 0
        var count: Int = 0
        var isLoading: Bool = false
    }

    private var metrics: [String: LoadingMetrics] = [:]

    func startLoading(_ identifier: String) {
        var current = metrics[identifier] ?? LoadingMetrics()

        // Only start if not already loading
        if !current.isLoading {
            current.startTime = Date()
            current.isLoading = true
            current.count += 1
            metrics[identifier] = current

            print("⏳ Started loading: \(identifier) (Attempt #\(current.count))")
        }
    }

    func endLoading(_ identifier: String) {
        guard var current = metrics[identifier],
            current.isLoading,
            let startTime = current.startTime
        else {
            print("⚠️ No start time found for: \(identifier)")
            return
        }

        let timeElapsed = Date().timeIntervalSince(startTime)
        current.totalTime += timeElapsed
        current.isLoading = false
        current.startTime = nil
        metrics[identifier] = current

        // Record loading metrics as client event
        Network.shared.recordClientEvent(
            event: ClientEvent(
                eventName: "loading_time",
                source: "loading_tracker",
                metadata: [
                    ["identifier": identifier],
                    ["time_elapsed_ms": Int(timeElapsed * 1000)],
                    ["attempt_number": current.count],
                    ["total_time_ms": Int(current.totalTime * 1000)],
                    ["average_time_ms": Int(current.totalTime / Double(current.count) * 1000)],
                ]
            )
        ) { result in
            switch result {
            case .success:
                print("✅ Recorded loading metrics for: \(identifier)")
            case .failure(let error):
                print("❌ Failed to record loading metrics: \(error)")
            }
        }

        print("✅ Finished loading: \(identifier)")
        print("   Time elapsed: \(String(format: "%.2f", timeElapsed))s")
        print("   Total attempts: \(current.count)")
        print("   Total time: \(String(format: "%.2f", current.totalTime))s")
        print(
            "   Average time: \(String(format: "%.2f", current.totalTime/Double(current.count)))s")
    }
}
