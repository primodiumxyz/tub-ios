import Foundation
import SwiftUI

struct IntervalStats {
  var volumeUsd: Double
  var trades: Int
  var priceChangePct: Double
}

struct PurchaseData: RawRepresentable {
    typealias RawValue = String
    
    let tokenId: String
    let timestamp: Date
    let amountToken: Int
    let priceUsd: Double
    
    init?(rawValue: RawValue) {
        // parse a JSON string to initialize the properties
        let json = try? JSONSerialization.jsonObject(with: rawValue.data(using: .utf8)!, options: [])
        let dict = json as? [String: Any]
        let timestampSeconds = dict?["timestamp"] as? TimeInterval ?? Date.now.timeIntervalSince1970
        self.timestamp = Date.init(timeIntervalSince1970: timestampSeconds)
        self.amountToken = dict?["amountToken"] as? Int ?? 0
        self.priceUsd = dict?["priceUsd"] as? Double ?? 0
        self.tokenId = dict?["tokenId"] as? String ?? ""
    }
    
    init(tokenId: String, timestamp: Date, amountToken: Int, priceUsd: Double) {
        self.tokenId = tokenId
        self.timestamp = timestamp
        self.amountToken = amountToken
        self.priceUsd = priceUsd
    }

    var rawValue: RawValue {
        // convert properties to a JSON string
        let dict: [String: Any] = [
            "timestamp": timestamp.timeIntervalSince1970,
            "amountToken": amountToken,
            "priceUsd": priceUsd,
            "tokenId": tokenId
        ]
        return try! JSONSerialization.data(withJSONObject: dict, options: []).base64EncodedString()
    }
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

  init(
    start: Date, end: Date, open: Double, close: Double, high: Double, low: Double, volume: Double
  ) {
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
  let quantityTokens: Int
  let isBuy: Bool
  let mint: String
}

struct StatValue: Identifiable {
  var id: String
  let title: String
  let caption: String?
  let value: String
  let color: Color?

  init(title: String, caption: String? = nil, value: String, color: Color? = nil) {
    self.id = title
    self.title = title
    self.caption = caption
    self.value = value
    self.color = color
  }
}

struct TokenData: Identifiable {
  var id: String { mint }
  let mint: String
  let metadata: TokenMetadata
  var liveData: TokenLiveData?

  var balanceToken: Int

  init(mint: String, balanceToken: Int = 0, metadata: TokenMetadata, liveData: TokenLiveData? = nil)
  {
    self.mint = mint
    self.balanceToken = balanceToken
    self.metadata = metadata
    self.liveData = liveData
  }
}

struct TokenMetadata {
  var name: String
  var symbol: String
  var description: String
  var imageUri: String
  var externalUrl: String
  var decimals: Int
  init(
    name: String,
    symbol: String,
    description: String,
    imageUri: String?,
    externalUrl: String?,
    decimals: Int
  ) {
    self.name = name
    self.symbol = symbol
    self.description = description
    self.imageUri = imageUri ?? ""
    self.externalUrl = externalUrl ?? ""
    self.decimals = decimals

  }
}

struct TokenLiveData {
  var marketCapUsd: Double
  var priceUsd: Double
  var stats: IntervalStats
  var recentStats: IntervalStats

  init(
    supply: Int,
    priceUsd: Double,
    stats: IntervalStats,
    recentStats: IntervalStats
  ) {
    // TODO: check if it's correct when QuickNode fixes their DAS API
    // 1. Is this ok to use that supply? do we need to use the circulating supply (that we don't have)?
    // 2. Does the supply need to be divided by 10 ** tokenDecimals?
    self.marketCapUsd = Double(supply) * priceUsd
      
    self.priceUsd = priceUsd
    self.stats = stats
    self.recentStats = recentStats
  }
}

enum PurchaseState {
  case buy
  case sell
}
