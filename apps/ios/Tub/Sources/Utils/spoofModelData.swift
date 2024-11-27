//
//  spoofModel.swift
//  Tub
//
//  Created by Henry on 11/27/24.
//

import Foundation

func spoofPriceModelData(_ model: SolPriceModel) {
    model.price = 100
    model.isReady = true
}

func spoofTokenModelData(_ model: TokenModel) {
    // Mock token data
    model.token = Token(
        id: "mock_token_id",
        name: "Mock Token",
        symbol: "MOCK",
        description: "A mock token for preview",
        imageUri: "https://example.com/mock.png",
        liquidityUsd: 1_000_000,
        marketCapUsd: 5_000_000,
        volumeUsd: 750_000,
        pairId: "mock_pair_id",
        socials: (discord: nil, instagram: nil, telegram: nil, twitter: nil, website: nil),
        uniqueHolders: 1500
    )

    // Set isReady to true
    model.isReady = true

    // Mock price data for the last hour (using CHART_INTERVAL)
    let now = Date()
    model.prices = (0..<60).map { i in
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
    model.candles = (0..<30).map { i in
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
            volume: 1000 + (i * 100)
        )
    }.reversed()
}
