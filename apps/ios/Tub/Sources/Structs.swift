import Foundation
import SwiftUI

struct Token: Identifiable {
    var id: String
    var name: String
    var symbol: String
    var mint: String
    var imageUri: String?
}

struct Price: Identifiable, Equatable {
    static func == (lhs: Price, rhs: Price) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.price == rhs.price
    }
    var id = UUID()
    var timestamp: Date
    var price: Double
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
    static func formatPrice(_ price: Double, showSign: Bool = true, maxDecimals: Int = 9) -> String {
        // Handle special cases
        if price.isNaN || price.isInfinite || price == 0 {
            return "0"
        }
        
        let absPrice = abs(price)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maxDecimals
        formatter.decimalSeparator = "."  // Use period for internal formatting
        formatter.groupingSeparator = ""  // Remove thousand separators
        
        if absPrice >= 1 {
            // For numbers 1 and above, use 3 decimal places maximum
            formatter.maximumFractionDigits = 3
            formatter.minimumFractionDigits = 0
        } else if absPrice < 0.001 {
            // For small numbers, ensure we show 3 significant digits
            let exponent = Int(floor(log10(absPrice)))
            
            formatter.minimumFractionDigits = -exponent + 2
            formatter.maximumFractionDigits = formatter.minimumFractionDigits
        } else {
            // For numbers between 0.001 and 1, use standard formatting
            formatter.minimumFractionDigits = 0
        }
        
        var result = formatter.string(from: NSNumber(value: price)) ?? String(format: "%.9f", price)
        
        // Ensure there's always a leading zero for decimal numbers
        if result.starts(with: ".") {
            result = "0" + result
        }
        
        // Remove trailing zeros after decimal point
        if result.contains(".") {
            result = result.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
            if result.hasSuffix(".") {
                result = String(result.dropLast())
            }
        }
        
        // Ensure there's always a leading zero for decimal numbers (again, after trimming)
        if result.starts(with: ".") {
            result = "0" + result
        }
        
        // Add subscript for small numbers
        if absPrice < 0.0001 && result.starts(with: "0.") {
            let parts = result.dropFirst(2).split(separator: "")
            var leadingZeros = 0
            for char in parts {
                if char == "0" {
                    leadingZeros += 1
                } else {
                    break
                }
            }
            if leadingZeros > 0 {
                let subscriptDigits = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
                let subscriptNumber = String(leadingZeros).map { subscriptDigits[Int(String($0))!] }.joined()
                result = "0.0\(subscriptNumber)" + result.dropFirst(2 + leadingZeros)
            }
        }
        
        if !showSign && result.hasPrefix("-") {
            result = result.replacingOccurrences(of: "-", with: "")
        }
        
        return result
    }
}
