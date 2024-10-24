//
//  SolPriceModel.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import Foundation

class SolPriceModel: ObservableObject {
    @Published var currentPrice: Double? = nil
    @Published var isReady: Bool = false
    @Published var error: String?
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    private var timer: Timer?
    
    init(mock: Bool = false) {
        if mock {
            self.currentPrice = 175
            isReady = true
        } else {
            fetchCurrentPrice()
        }
    }
    
 
    func fetchCurrentPrice() {
        isReady = false
        error = nil
        
        Network.shared.fetchSolPrice { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let price):
                    self?.currentPrice = price
                    print("Fetched SOL price: \(price)")
                case .failure(let fetchError):
                    self?.error = fetchError.localizedDescription
                    print("Error fetching SOL price: \(fetchError.localizedDescription)")
                }
                self?.isReady = true
            }
        }
    }
    
    private func getFormattingParameters(for value: Double) -> (minFractionDigits: Int, maxFractionDigits: Int) {
        let absValue = abs(value)
        if absValue >= 1 {
            return (2, 3)
        } else if absValue < 0.001 {
            let exponent = Int(floor(log10(absValue)))
            let digits = -exponent + 2
            return (2, digits)
        } else {
            return (2, 9)
        }
    }
    
    private func formatInitial(_ value: Double, minFractionDigits: Int, maxFractionDigits: Int) -> String {
        formatter.minimumFractionDigits = minFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.9f", value)
    }
    
    private func cleanupFormattedString(_ str: String) -> String {
        var result = str
        if result.starts(with: ".") {
            result = "0" + result
        }
        if result.contains(".") {
            result = result.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
            if result.hasSuffix(".") {
                result = String(result.dropLast())
            }
        }
        if result.starts(with: ".") {
            result = "0" + result
        }
        if !result.contains(".") {
            result += ".00"
        } else {
            let decimalPart = result.split(separator: ".").last ?? ""
            if decimalPart.count < 2 {
                result += String(repeating: "0", count: 2 - decimalPart.count)
            }
        }
        return result
    }
    
    func formatPrice(sol: Double, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9) -> String {
        if let price = currentPrice, price > 0 {
            if sol.isNaN || sol.isInfinite || sol == 0 {
                return showUnit ? "$0.00" : "0.00"
            }
            
            let usdPrice = sol * price
            let (minFractionDigits, maxFractionDigits) = getFormattingParameters(for: usdPrice)
            var result = formatInitial(usdPrice, minFractionDigits: minFractionDigits, maxFractionDigits: min(maxFractionDigits, maxDecimals))
            
            result = cleanupFormattedString(result)
            
            let isNegative = result.hasPrefix("-")
            result = result.replacingOccurrences(of: "-", with: "")
            
            var prefix = ""
            if showSign {
                prefix += isNegative ? "-" : "+"
            }
            if showUnit {
                prefix += "$"
            }
            
            return prefix + result
        } else {
            return "0.00"
        }
    }
    
    func formatPrice(lamports: Int, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9) -> String {
        let solPrice = Double(lamports) / 1e9
        return formatPrice(sol: solPrice, showSign: showSign, showUnit: showUnit, maxDecimals: maxDecimals)
    }
    
    func formatPrice(usd: Double, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9) -> String {
        if let price = currentPrice, price > 0 {
            return formatPrice(sol: usd / price, showSign: showSign, showUnit: showUnit, maxDecimals: maxDecimals)
        } else {
            return "0.00"
        }
    }

    func usdToLamports(usd: Double) -> Int {
        if let price = currentPrice {
            return Int(usd * 1e9 / price)
        } else {
            return 0
        }
    }

    func lamportsToUsd(lamports: Int) -> Double {
        if let price = currentPrice {
            return Double(lamports) * price / 1e9
        } else {
            return 0
        }
    }
}
