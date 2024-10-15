import Foundation
import SwiftUI

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
    let name: String
    let symbol: String
    let imageUri: String
    let date: Date
    let value: Double
    let quantity: Double
    let isBuy: Bool
}

var neonBlue = Color(red: 0.43, green: 0.97, blue: 0.98)
