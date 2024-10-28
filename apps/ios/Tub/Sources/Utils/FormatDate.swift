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

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

func formatDateString(_ dateString: String) -> Date? {
    return iso8601Formatter.date(from: dateString)
}

func formatDate(_ date: Date) -> String {
    return dateFormatter.string(from: date)
}

func formatTime(_ date: Date) -> String {
    return timeFormatter.string(from: date)
}
