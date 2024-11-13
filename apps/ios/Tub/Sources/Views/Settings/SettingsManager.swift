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
    
    init() {
        self.isVibrationEnabled = UserDefaults.standard.object(forKey: "isVibrationEnabled") as? Bool ?? true
        print("Initial haptic feedback state: \(isVibrationEnabled ? "🟢 ON" : "🔴 OFF")")
    }
} 
