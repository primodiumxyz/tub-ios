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

func formatDuration(_ seconds: TimeInterval) -> String {
    if seconds < 60 {
        return String(format: "%.0fs", seconds)
    }

    if seconds < 3600 {
        let minutes = floor(seconds / 60)
//no longer needed?        let remainingSeconds = seconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%.0fm", minutes)
    }

    let hours = floor(seconds / 3600)
    let remainingMinutes = floor(seconds.truncatingRemainder(dividingBy: 3600) / 60)
    if remainingMinutes == 0 {
        return String(format: "%.0fh", hours)
    }
    return String(format: "%.0fh %.0fm", hours, remainingMinutes)
}
