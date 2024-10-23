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
    
    private static func getFormattingParameters(for value: Double) -> (minimumFractionDigits: Int, maximumFractionDigits: Int) {
        let absValue = abs(value)
        if absValue >= 1 {
            return (0, 3)
        } else if absValue < 0.001 {
            let exponent = Int(floor(log10(absValue)))
            let digits = -exponent + 2
            return (digits, digits)
        } else {
            return (0, 5)
        }
    }

    private static func formatInitial(_ value: Double, minimumFractionDigits: Int, maximumFractionDigits: Int) -> String {
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
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

    static func formatPrice(sol: Double, showSign: Bool = true, maxDecimals: Int = 9) -> String {
        if sol.isNaN || sol.isInfinite || sol == 0 {
            return "0"
        }

        let (minFractionDigits, maxFractionDigits) = getFormattingParameters(for: sol)
        var result = formatInitial(sol, minimumFractionDigits: minFractionDigits, maximumFractionDigits: min(maxFractionDigits, maxDecimals))
        
        result = cleanupFormattedString(result)

        if !showSign && result.hasPrefix("-") {
            result = result.replacingOccurrences(of: "-", with: "")
        }

        return result
    }
    
    static func formatPrice(lamports: Int, showSign: Bool = true, maxDecimals: Int = 9) ->
    String {
        let solPrice = Double(lamports) / 1e9
        return self.formatPrice(sol: solPrice, showSign: showSign, maxDecimals: maxDecimals)
    }
}
