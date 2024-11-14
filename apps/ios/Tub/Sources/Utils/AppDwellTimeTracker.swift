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

    Network.shared.recordClientEvent(
      event: ClientEvent(
        eventName: "app_dwell_time",
        source: "app",
        metadata: [
          ["dwell_time_ms": dwellTimeMs]
        ]
      )
    ) { result in
      switch result {
      case .success:
        print("✅ Recorded app dwell time: \(dwellTimeMs)ms")
      case .failure(let error):
        print("❌ Failed to record app dwell time: \(error)")
      }
    }

    startTime = nil
    print("📱 App session ended")
  }
}
