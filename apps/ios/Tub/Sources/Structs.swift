import Foundation
import SwiftUI

struct Token: Identifiable {
    var id: String
    var name: String
    var symbol: String
    var mint: String
    var decimals: Int
    var imageUri: String?
}

struct Price: Identifiable, Equatable {
    static func == (lhs: Price, rhs: Price) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.price == rhs.price
    }
    var id = UUID()
    var timestamp: Date
    var price: Int
}

struct Transaction: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let symbol: String
    let imageUri: String
    let date: Date
    let valueUsd: Double
    let quantityTokens: Int
    let isBuy: Bool
}

