//
//  SettingsManager.swift
//  Tub
//
//  Created by Yi Xin Tan on 2024/11/12.
//
import SwiftUI
import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var isVibrationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isVibrationEnabled, forKey: "isVibrationEnabled")
            print("Haptic feedback is now \(isVibrationEnabled ? "🟢 ON" : "🔴 OFF")")
        }
    }
    
    @Published var defaultBuyValue: Double {
        didSet {
            UserDefaults.standard.set(defaultBuyValue, forKey: "defaultBuyValue")
            print("Default buy value updated to: $\(String(format: "%.2f", defaultBuyValue))")
        }
    }
    
    init() {
        self.isVibrationEnabled = UserDefaults.standard.object(forKey: "isVibrationEnabled") as? Bool ?? true
        self.defaultBuyValue = UserDefaults.standard.object(forKey: "defaultBuyValue") as? Double ?? 10.00
        print("Initial haptic feedback state: \(isVibrationEnabled ? "🟢 ON" : "🔴 OFF")")
        print("Initial default buy value: $\(String(format: "%.2f", defaultBuyValue))")
    }
} 
