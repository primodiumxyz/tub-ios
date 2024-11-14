import Foundation
import SwiftUI

struct Token: Identifiable {
    var id: String // also mint
    var name: String
    var symbol: String
    var description: String
    var imageUri: String
    var liquidity: Double
    var marketCap: Double
    var volume: Double
    var pairId: String
    
    init(id: String, name: String, symbol: String, description: String?, imageUri: String?, liquidity: String, marketCap: String?, volume: String, pairId: String) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.description = description ?? "DESCRIPTION"
        self.imageUri = imageUri?.replacingOccurrences(of: "cf-ipfs.com", with: "ipfs.io") ?? "" // sometimes this prefix gets added and it bricks it
        self.liquidity = Double(liquidity) ?? 0
        self.marketCap = Double(marketCap ?? "0") ?? 0
        self.volume = Double(volume) ?? 0
        self.pairId = pairId
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

    struct StatValue {
        let text: String
        let color: Color?
    }
