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
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"  // Adjust format as needed
    return dateFormatter.date(from: dateString)
}

// Dummy Data for Transactions
let dummyData = [
    TransactionData(
        name: "Monkey",
        symbol: "$MONKAY",
        imageUri: "monkey_icon",
        date: dateFromString("2024-10-07 09:12")!,
        valueUsd: -320,
        valueLamps: 0,
        quantityTokens: 2_332_100,
        isBuy: true,
        mint: ""
    ),
    TransactionData(
        name: "Monkey",
        symbol: "$MONKAY",
        imageUri: "monkey_icon",
        date: dateFromString("2024-10-02 14:30")!,
        valueUsd: 233,
        valueLamps: 0,
        quantityTokens: 1_222_100,
        isBuy: false,
        mint: ""
    ),
    TransactionData(
        name: "Monkey",
        symbol: "$MONKAY",
        imageUri: "monkey_icon",
        date: dateFromString("2024-10-01 16:45")!,
        valueUsd: -90,
        valueLamps: 0,
        quantityTokens: 1_222_100,
        isBuy: true,
        mint: ""
    ),
    TransactionData(
        name: "Pepe",
        symbol: "$PEPEGG",
        imageUri: "pepe_icon",
        date: dateFromString("2024-09-30 11:00")!,
        valueUsd: 142,
        valueLamps: 0,
        quantityTokens: 22100,
        isBuy: false,
        mint: ""
    ),
    TransactionData(
        name: "Pepe",
        symbol: "$PEPEGG",
        imageUri: "pepe_icon",
        date: dateFromString("2024-09-28 18:25")!,
        valueUsd: -120,
        valueLamps: 0,
        quantityTokens: 22100,
        isBuy: true,
        mint: ""
    ),
]

let mockTokenId = "722e8490-e852-4298-a250-7b0a399fec57"
