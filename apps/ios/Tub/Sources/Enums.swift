//
//  Enums.swift
//  Tub
//
//  Created by polarzero on 20/11/2024.
//

enum Timespan: String, CaseIterable {
    case live = "LIVE"
    case candles = "30M"

    public var seconds: Double {
        switch self {
            case .live: return CHART_INTERVAL
            case .candles: return CANDLES_INTERVAL
        }
    }
}
