import SwiftUI
import Foundation

struct Token: Identifiable {
    var id: String
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
    let symbol: String
    let date: Date
    let amount: Double
    let quantity: Double
    let isBuy: Bool
}
