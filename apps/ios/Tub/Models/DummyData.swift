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
    Transaction(coin: "$MONKAY", date: dateFromString("2024-10-07 09:12")!, amount: -320.00, quantity: 2332100, isBuy: true),
    Transaction(coin: "$MONKAY", date: dateFromString("2024-10-02 14:30")!, amount: 233.22, quantity: 1222100, isBuy: false),
    Transaction(coin: "$MONKAY", date: dateFromString("2024-10-01 16:45")!, amount: -90.00, quantity: 1222100, isBuy: true),
    Transaction(coin: "$PEPEGG", date: dateFromString("2024-09-30 11:00")!, amount: 142.12, quantity: 22100, isBuy: false),
    Transaction(coin: "$PEPEGG", date: dateFromString("2024-09-28 18:25")!, amount: -120.00, quantity: 22100, isBuy: true)
]
