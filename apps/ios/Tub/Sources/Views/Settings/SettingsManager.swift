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

    @Published var defaultBuyValueUsdc: Int {
        didSet {
            UserDefaults.standard.set(defaultBuyValueUsdc, forKey: "defaultBuyValue")
        }
    }

    init() {
        self.isVibrationEnabled = UserDefaults.standard.object(forKey: "isVibrationEnabled") as? Bool ?? true
        self.defaultBuyValueUsdc = UserDefaults.standard.object(forKey: "defaultBuyValue") as? Int ?? SolPriceModel.shared.usdToUsdc(usd: 10)
    }
}
