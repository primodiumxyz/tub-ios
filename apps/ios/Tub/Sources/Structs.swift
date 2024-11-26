import Foundation
import SwiftUI

struct Token: Identifiable {
    var id: String  // also mint
    var name: String
    var symbol: String
    var description: String
    var imageUri: String
    var liquidity: Double
    var marketCap: Double
    var volume: Double
    var pairId: String
    var socials: (discord: String?, instagram: String?, telegram: String?, twitter: String?, website: String?)
    var uniqueHolders: Int

    init(
        id: String?,
        name: String?,
        symbol: String?,
        description: String?,
        imageUri: String?,
        liquidity: Double?,
        marketCap: Double?,
        volume: Double?,
        pairId: String?,
        socials: (discord: String?, instagram: String?, telegram: String?, twitter: String?, website: String?),
        uniqueHolders: Int?
    ) {
        self.id = id ?? ""
        self.name = name ?? "NAME"
        self.symbol = symbol ?? "SYMBOL"
        self.description = description ?? "DESCRIPTION"
        self.imageUri = imageUri?.replacingOccurrences(of: "cf-ipfs.com", with: "ipfs.io") ?? ""  // sometimes this prefix gets added and it bricks it
        self.liquidity = liquidity ?? 0.0
        self.marketCap = marketCap ?? 0.0
        self.volume = volume ?? 0.0
        self.pairId = pairId ?? ""
        self.socials = socials
        self.uniqueHolders = uniqueHolders ?? 0
    }
}

struct PurchaseData {
    let timestamp: Date
    let amountUsdc: Int
    let priceUsdc: Int
}

struct Price: Identifiable, Equatable {
    static func == (lhs: Price, rhs: Price) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.priceUsd == rhs.priceUsd
    }
    var id = UUID()
    var timestamp: Date
    var priceUsd: Double
}

struct CandleData: Equatable, Identifiable {
    let id: Date
    let start: Date
    let end: Date
    let open: Double
    var close: Double
    var high: Double
    var low: Double
    var volume: Int?

    init(start: Date, end: Date, open: Double, close: Double, high: Double, low: Double, volume: Int? = nil) {
        self.id = start
        self.start = start
        self.end = end
        self.open = open
        self.close = close
        self.high = high
        self.low = low
        self.volume = volume
    }
}

struct Transaction: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let symbol: String
    let imageUri: String
    let date: Date
    let valueUsd: Double
    let valueUsdc: Int
    let quantityTokens: Int
    let isBuy: Bool
    let mint: String
}

struct StatValue {
    let text: String
    let color: Color?
}

enum PurchaseState {
    case buy
    case sell
}
