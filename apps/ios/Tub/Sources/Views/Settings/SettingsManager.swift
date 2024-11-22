import Foundation
//
//  SettingsManager.swift
//  Tub
//
//  Created by Yi Xin Tan on 2024/11/12.
//
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var isVibrationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isVibrationEnabled, forKey: "isVibrationEnabled")
        }
    }

    @Published var defaultBuyValue: Double {
        didSet {
            UserDefaults.standard.set(defaultBuyValue, forKey: "defaultBuyValue")
        }
    }

    init() {
        self.isVibrationEnabled = UserDefaults.standard.object(forKey: "isVibrationEnabled") as? Bool ?? true
        self.defaultBuyValue = UserDefaults.standard.object(forKey: "defaultBuyValue") as? Double ?? 10.00
    }
}
