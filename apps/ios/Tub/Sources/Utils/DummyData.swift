//
//  DummyData.swift
//  Tub
//
//  Created by yixintan on 10/7/24.
//

import Foundation

// Helper function to convert a string to Date
func dateFromString(_ dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // Adjust format as needed
    return dateFormatter.date(from: dateString)
}

// Dummy Data for Transactions
let dummyData = [
    Transaction(name: "Monkey", symbol: "$MONKAY", imageUri: "monkey_icon", date: dateFromString("2024-10-07 09:12")!, valueUsd: -320, quantityTokens: 2332100, isBuy: true, mint: ""),
    Transaction(name: "Monkey", symbol: "$MONKAY", imageUri: "monkey_icon", date: dateFromString("2024-10-02 14:30")!, valueUsd: 233, quantityTokens: 1222100, isBuy: false, mint: ""),
    Transaction(name: "Monkey", symbol: "$MONKAY", imageUri: "monkey_icon", date: dateFromString("2024-10-01 16:45")!, valueUsd: -90, quantityTokens: 1222100, isBuy: true, mint: ""),
    Transaction(name: "Pepe", symbol: "$PEPEGG", imageUri: "pepe_icon", date: dateFromString("2024-09-30 11:00")!, valueUsd: 142, quantityTokens: 22100, isBuy: false, mint: ""),
    Transaction(name: "Pepe", symbol: "$PEPEGG", imageUri: "pepe_icon", date: dateFromString("2024-09-28 18:25")!, valueUsd: -120, quantityTokens: 22100, isBuy: true, mint: "")
]

let mockTokenId = "722e8490-e852-4298-a250-7b0a399fec57"
