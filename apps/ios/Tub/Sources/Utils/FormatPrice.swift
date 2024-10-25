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
    formatter.locale = Locale(identifier: "en_US") // Set the locale to US
    return formatter
}()

func getFormattingParameters(for value: Double) -> (minFractionDigits: Int, maxFractionDigits: Int) {
    let absValue = abs(value)
    if absValue >= 1 {
        return (0, 3)
    } else {
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
    if absPrice < 0.0001 && str.starts(with: "0.") {
        let parts = str.dropFirst(2).split(separator: "")
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
            result = "0.0\(subscriptNumber)" + str.dropFirst(2 + leadingZeros)
        }
    }
        // Flip periods and commas if the current locale uses periods as decimal separators
    if Locale.current.decimalSeparator == "," {
        result = result.replacingOccurrences(of: ",", with: "⍼")
            .replacingOccurrences(of: ".", with: ",")
            .replacingOccurrences(of: "⍼", with: ".")
    }
    
    return result
}
