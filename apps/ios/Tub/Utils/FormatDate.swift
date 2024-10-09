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
    return iso8601Formatter.date(from: dateString)
}

