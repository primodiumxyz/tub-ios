//
//  spoofModel.swift
//  Tub
//
//  Created by Henry on 11/27/24.
//

import Foundation

func spoofPriceModelData(_ model: SolPriceModel) {
    model.solPrice = 100
}

func spoofTokenModelData(userModel: UserModel, tokenModel: TokenModel) {
    // Mock token data
    Task { @MainActor in
        await userModel.updateTokenData(
            mint: "mock_token_id",
            balance: 0,
            metadata: TokenMetadata(
                name: "Mock Token",
                symbol: "MOCK",
                description: "A mock token for preview",
                imageUri: "https://example.com/mock.png",
                externalUrl: "https://example.com/mock",
                decimals: 6
            ),
            liveData: TokenLiveData(
                supply: 1_000_000_000,
                priceUsd: 0.0075,
                stats: IntervalStats(volumeUsd: 750_000, trades: 370, priceChangePct: 17.3),
                recentStats: IntervalStats(volumeUsd: 8_000, trades: 27, priceChangePct: 3.46)
            )
        )
        
        // Set isReady to true
        tokenModel.updateTokenDetails("mock_token_id")
        tokenModel.isReady = true
    }

    // Mock price data for the last hour (using CHART_INTERVAL)
    let now = Date()
    tokenModel.prices = (0..<60).map { i in
        let timestamp = now.addingTimeInterval(-Double(i) * PRICE_UPDATE_INTERVAL)
        // Create a sine wave pattern for visual interest
        let basePrice = 100.0
        let variation = sin(Double(i) / 10.0) * 10.0
        return Price(
            timestamp: timestamp,
            priceUsd: basePrice + variation
        )
    }.reversed()

    // Mock candle data for the last 30 minutes (using CANDLES_INTERVAL)
    tokenModel.candles = (0..<30).map { i in
        let start = now.addingTimeInterval(-Double(i) * 60)
        let end = start.addingTimeInterval(60)
        // Create some variation in the candle data
        let basePrice = 100.0
        let variation = Double(i % 5) * 2.0
        return CandleData(
            start: start,
            end: end,
            open: basePrice + variation,
            close: basePrice + variation + 1,
            high: basePrice + variation + 2,
            low: basePrice + variation - 1,
            volume: Double(1000 + (i * 100)),
            hasTrades: true
        )
    }.reversed()
}
var spoofPrices: [Price] = [
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_635), priceUsd: 0.000688625530256),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_637), priceUsd: 0.000688625530256),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_639), priceUsd: 0.000691385308088),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_641), priceUsd: 0.000691385308088),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_643), priceUsd: 0.000718947605594),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_645), priceUsd: 0.000713516161119),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_647), priceUsd: 0.000705367277412),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_649), priceUsd: 0.000704217103182),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_651), priceUsd: 0.000704060503112),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_653), priceUsd: 0.000684881773025),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_655), priceUsd: 0.000678182479761),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_657), priceUsd: 0.000676460654247),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_659), priceUsd: 0.000679194840476),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_661), priceUsd: 0.000696030406735),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_663), priceUsd: 0.00078628018795),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_665), priceUsd: 0.000801697835232),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_667), priceUsd: 0.000833142607234),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_669), priceUsd: 0.000825006766618),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_671), priceUsd: 0.000823535078927),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_673), priceUsd: 0.000823655627316),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_675), priceUsd: 0.00077535659348),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_677), priceUsd: 0.00077535659348),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_679), priceUsd: 0.00077535659348),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_681), priceUsd: 0.00077313700959),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_683), priceUsd: 0.000781810534043),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_685), priceUsd: 0.000794070647025),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_687), priceUsd: 0.000785387367033),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_689), priceUsd: 0.000785487632957),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_691), priceUsd: 0.000788875082779),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_693), priceUsd: 0.000774658210176),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_695), priceUsd: 0.000774658210176),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_697), priceUsd: 0.000792151282824),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_699), priceUsd: 0.000792151282824),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_701), priceUsd: 0.000785523645051),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_703), priceUsd: 0.000759895038998),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_705), priceUsd: 0.000765264256225),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_707), priceUsd: 0.000765264256225),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_709), priceUsd: 0.000754258844542),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_711), priceUsd: 0.000750553317441),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_713), priceUsd: 0.00081182446668),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_715), priceUsd: 0.000813021002706),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_717), priceUsd: 0.000796599543544),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_719), priceUsd: 0.000797099791486),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_721), priceUsd: 0.000797099791486),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_723), priceUsd: 0.000797099791486),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_726), priceUsd: 0.000797099791486),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_727), priceUsd: 0.000785758112708298),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_727), priceUsd: 0.000785758112708298),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_728), priceUsd: 0.000785758112708298),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_728), priceUsd: 0.000785758112708298),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_729), priceUsd: 0.0007875247240578811),
    Price(timestamp: Date(timeIntervalSince1970: 1_701_118_729), priceUsd: 0.0007875247240578811),
]
