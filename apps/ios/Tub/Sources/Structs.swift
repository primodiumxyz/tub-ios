import Foundation
import SwiftUI

struct Token: Identifiable {
    var id: String
    var mint: String
    var name: String
    var symbol: String
    var description: String
    var supply: Int
    var decimals: Int
    var imageUri: String
    var volume: (value: Int, interval: String)
    
    init(id: String, mint: String, name: String?, symbol: String?, description: String?, supply: Int?, decimals: Int?, imageUri: String?, volume: (value: Int, interval: String)? = nil) {
        self.id = id
        self.mint = mint
        self.name = name ?? "COIN"
        self.symbol = symbol ?? "SYMBOL"
        self.description = description ?? "DESCRIPTION"
        self.supply = supply ?? 0
        self.decimals = decimals ?? 6
        self.imageUri = imageUri?.replacingOccurrences(of: "cf-ipfs.com", with: "ipfs.io") ?? "" // sometimes this prefix gets added and it bricks it
        self.volume = volume ?? (0, CHART_INTERVAL)
    }
}

struct PurchaseData {
    let timestamp: Date
    let amount: Int
    let price: Int
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
    let valueLamps: Int
    let quantityTokens: Int
    let isBuy: Bool
    let mint: String
}

