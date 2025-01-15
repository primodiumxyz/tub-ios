//
//  FormatPrice.swift
//  Tub
//
//  Created by Henry on 10/24/24.
//
import Foundation

let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal

    return formatter
}()

func getFormattingParameters(for value: Double) -> (minFractionDigits: Int, maxFractionDigits: Int) {
    let absValue = abs(value)
    if absValue >= 1 {
        return (0, 3)
    }
    else {
        let exponent = Int(floor(log10(absValue)))
        let digits = -exponent + 2
        return (0, digits)
    }
}

func formatInitial(_ value: Double, minFractionDigits: Int, maxFractionDigits: Int) -> String {
    formatter.minimumFractionDigits = minFractionDigits
    formatter.maximumFractionDigits = maxFractionDigits
    let ret = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.9f", value)
    return ret
}

func cleanupFormattedString(_ str: String) -> String {
    var result = str
    if result.starts(with: ".") {
        result = "0" + result
    }

    // Add subscript for small numbers
    let absPrice = abs(Double(str) ?? 0.0)
    if absPrice < 0.0001 && absPrice > 0 {
        let parts = result.dropFirst(2).split(separator: "")
        var leadingZeros = 0
        for char in parts {
            if char == "0" {
                leadingZeros += 1
            }
            else {
                break
            }
        }
        if leadingZeros > 0 {
            let subscriptDigits = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
            let subscriptNumber = String(leadingZeros).map { subscriptDigits[Int(String($0))!] }.joined()
            result = "0.0\(subscriptNumber)" + result.dropFirst(2 + leadingZeros)
        }
    }

    return result
}

func formatLargeNumber(_ value: Double) -> String {
    let absValue = abs(value)
    switch absValue {
    case 1_000_000_000_000...:
        return "\(String(format: "%.1fT", value / 1_000_000_000_000))"
    case 1_000_000_000...:
        return "\(String(format: "%.1fB", value / 1_000_000_000))"
    case 1_000_000...:
        return "\(String(format: "%.1fM", value / 1_000_000))"
    case 1_000...:
        return "\(String(format: "%.1fK", value / 1_000))"
    default:
        return String(value)
    }
}

    func formatPriceUsd(
        usd: Double,
        showSign: Bool = false,
        showUnit: Bool = true,
        maxDecimals: Int = 9,
        minDecimals: Int = 2,
        formatLarge: Bool = true
    ) -> String {
        if usd.isNaN || usd.isInfinite || usd == 0 {
            return showUnit ? "$0.00" : "0.00"
        }

        // Handle large numbers
        if usd >= 10_000 && formatLarge {
            return
                "\(showSign ? (usd >= 0 ? "+" : "") : "")\(showUnit ? "$" : "")\(formatLargeNumber(usd))"
        }

        let (minFractionDigits, maxFractionDigits) = getFormattingParameters(for: usd)
        var result = formatInitial(
            usd,
            minFractionDigits: max(minFractionDigits, minDecimals),
            maxFractionDigits: min(maxFractionDigits, maxDecimals)
        )

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
