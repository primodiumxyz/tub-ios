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

    private var show = false
    private var metrics: [String: LoadingMetrics] = [:]

    func startLoading(_ identifier: String) {
        var current = metrics[identifier] ?? LoadingMetrics()

        // Only start if not already loading
        if !current.isLoading {
            current.startTime = Date()
            current.isLoading = true
            current.count += 1
            metrics[identifier] = current

            if show {
                print("⏳ Started loading: \(identifier) (Attempt #\(current.count))")
            }
        }
    }

    func endLoading(_ identifier: String) {
        guard var current = metrics[identifier],
            current.isLoading,
            let startTime = current.startTime
        else {
            if show {
                print("⚠️ No start time found for: \(identifier)")
            }
            return
        }

        let timeElapsed = Date().timeIntervalSince(startTime)
        current.totalTime += timeElapsed
        current.isLoading = false
        current.startTime = nil
        metrics[identifier] = current

        // Record loading metrics as client event
        Task(priority: .low) {
            try? await Network.shared.recordLoadingTime(
                identifier: identifier,
                timeElapsedMs: Int(timeElapsed * 1000),
                attemptNumber: current.count,
                totalTimeMs: Int(current.totalTime * 1000),
                averageTimeMs: Int(current.totalTime / Double(current.count) * 1000),
                source: "loading_tracker",
                errorDetails: nil
            )
            print("✅ Recorded loading metrics for: \(identifier)")
        }

        if show {
            print("✅ Finished loading: \(identifier)")
            print("   Time elapsed: \(String(format: "%.2f", timeElapsed))s")
            print("   Total attempts: \(current.count)")
            print("   Total time: \(String(format: "%.2f", current.totalTime))s")
            print(
                "   Average time: \(String(format: "%.2f", current.totalTime/Double(current.count)))s"
            )
        }
    }
}
