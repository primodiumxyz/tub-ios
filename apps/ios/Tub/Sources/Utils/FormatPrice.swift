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
    formatter.decimalSeparator = "."
    formatter.groupingSeparator = ""
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
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.9f", value)
}

func cleanupFormattedString(_ str: String) -> String {
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
