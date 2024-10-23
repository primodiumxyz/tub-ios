import Foundation
import SwiftUI

struct Token: Identifiable {
    var id: String
    var name: String
    var symbol: String
    var mint: String
    var decimals: Int
    var imageUri: String?
}

struct Price: Identifiable, Equatable {
    static func == (lhs: Price, rhs: Price) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.price == rhs.price
    }
    var id = UUID()
    var timestamp: Date
    var price: Int
}

struct Transaction: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let symbol: String
    let imageUri: String
    let date: Date
    let value: Double
    let quantity: Double
    let isBuy: Bool
}

struct PriceFormatter {
    // Show only 3 significant digits, meaning:
    // - for numbers below 1, show 3 significant digits, up to 9 decimal places
    // - for numbers above 1, show 3 decimal places maximum
    // - for numbers below 0.0001, show a subscript (e.g. like on DexScreener) to make the number more readable
    // e.g. 0.0000004932 -> 0.0₆4932
    // - remove trailing zeros after decimal point
    // The logic is super convoluted because it's super tricky to get it right, but it works like that;
    // we just lose the locale formatting.
    
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."  // Use period for internal formatting
        formatter.groupingSeparator = ""  // Remove thousand separators
        return formatter
    }()
    
    private static let solPriceModel = SolPriceModel()
    
    private static func getFormattingParameters(for value: Double) -> (minFractionDigits: Int, maxFractionDigits: Int) {
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
    
    private static func formatInitial(_ value: Double, minFractionDigits: Int, maxFractionDigits: Int) -> String {
        formatter.minimumFractionDigits = minFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.9f", value)
    }
    
    private static func cleanupFormattedString(_ str: String) -> String {
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
        return result
    }
    
    static func formatPrice(sol: Double, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9) -> String {
        if sol.isNaN || sol.isInfinite || sol == 0 {
            if(showUnit) {
                return "$0.00"
            } else {
                return "0.00"
            }
        }
        
        let usdPrice = sol * solPriceModel.currentPrice
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
    }
    
    static func formatPrice(lamports: Int, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9) -> String {
        let solPrice = Double(lamports) / 1e9
        return self.formatPrice(sol: solPrice, showSign: showSign, showUnit: showUnit, maxDecimals: maxDecimals)
    }
    
    static func formatPrice(usd: Double, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9) -> String {
        return self.formatPrice(sol: usd / solPriceModel.currentPrice, showSign: showSign, showUnit: showUnit, maxDecimals: maxDecimals)
    }

    static func usdToLamports(usd: Double) -> Int {
        return Int(usd * 1e9 / solPriceModel.currentPrice)
    }

    static func lamportsToUsd(lamports: Int) -> Double {
        return Double(lamports) * solPriceModel.currentPrice / 1e9
    }
}
