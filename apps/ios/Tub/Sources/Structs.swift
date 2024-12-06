import Foundation
import SwiftUI

struct IntervalStats {
    var volumeUsd: Double
    var trades: Int
    var priceChangePct: Double
}

struct Token: Identifiable {
    var id: String // also mint
    var name: String
    var symbol: String
    var description: String
    var imageUri: String
    var externalUrl: String
    var marketCapUsd: Double
    var stats: IntervalStats
    var recentStats: IntervalStats

    init(
        id: String,
        name: String,
        symbol: String,
        description: String,
        imageUri: String?,
        externalUrl: String?,
        supply: Int,
        latestPriceUsd: Double,
        stats: IntervalStats,
        recentStats: IntervalStats
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.description = description
        self.imageUri = imageUri ?? ""
        self.externalUrl = externalUrl ?? ""
        // TODO: check if it's correct when QuickNode fixes their DAS API
        // 1. Is this ok to use that supply? do we need to use the circulating supply (that we don't have)?
        // 2. Does the supply need to be divided by 10 ** tokenDecimals?
        self.marketCapUsd = Double(supply) * latestPriceUsd
        self.stats = stats
        self.recentStats = recentStats
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
    var volume: Double?

    init(start: Date, end: Date, open: Double, close: Double, high: Double, low: Double, volume: Double) {
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

struct TransactionData: Identifiable, Equatable {
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

struct StatValue: Identifiable {
    var id: String
    let title: String
    let value: String
    let color: Color?

    init(title: String, value: String, color: Color? = nil) {
        self.id = title
        self.title = title
        self.value = value
        self.color = color
    }
}

enum PurchaseState {
    case buy
    case sell
}
