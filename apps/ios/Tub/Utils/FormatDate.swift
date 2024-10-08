//
//  FormatTimestamp.swift
//  Tub
//
//  Created by Henry on 10/8/24.
//
import Foundation

var iso8601Formatter: ISO8601DateFormatter = {
    
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

func formatDate(_ dateString: String) -> Date? {
    let pattern = #"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\.(\d{6})"#
    
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
          let match = regex.firstMatch(in: dateString, options: [], range: NSRange(dateString.startIndex..., in: dateString)) else {
        return nil
    }
    
    let dateRange = Range(match.range(at: 1), in: dateString)!
    let millisRange = Range(match.range(at: 2), in: dateString)!
    
    let datePart = String(dateString[dateRange])
    let millisPart = String(dateString[millisRange].prefix(3))
    
    return iso8601Formatter.date(from: datePart + "." + millisPart + "Z")
}

