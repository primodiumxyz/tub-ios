import SwiftUI

struct Coin: Identifiable {
    let id: String
    var name: String
    var symbol: String
}

struct Price: Identifiable {
    var id = UUID()
    var timestamp: Date
    var price: Double
}

struct Transaction: Identifiable, Equatable {
    let id = UUID()
    let coin: String
    let date: Date
    let amount: Double
    let quantity: Int
    let isBuy: Bool
}
