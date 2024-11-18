//
//  CandleChartView.swift
//  Tub
//
//  Created by Henry on 10/17/24.
//

import SwiftUI
import Charts

struct CandleChartView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    let candles: [CandleData]
    let timeframeMins: Double
    let height: CGFloat

    init(candles: [CandleData], timeframeMins: Double = 30, height: CGFloat = 330) {
        self.candles = candles
        self.timeframeMins = timeframeMins
        self.height = height
    }

    private var yDomain: ClosedRange<Double> {
        if candles.isEmpty { return 0...100 }
        
        let minPrice = candles.min { $0.low < $1.low }?.low ?? 0
        let maxPrice = candles.max { $0.high < $1.high }?.high ?? 100
        let range = maxPrice - minPrice
        let padding = range * 0.25
        
        return (minPrice - padding)...(maxPrice + padding)
    }
    
    var body: some View {
        Chart {
            ForEach(candles) { candle in
                // Candlestick body
                RectangleMark(
                    x: .value("Time", candle.start),
                    yStart: .value("Open", candle.open),
                    yEnd: .value("Close", candle.close),
                    width: 8
                )
                .foregroundStyle(candle.close >= candle.open ? AppColors.green : AppColors.red)

                // High-Low line
                RuleMark(
                    x: .value("Time", candle.start),
                    yStart: .value("High", candle.high),
                    yEnd: .value("Low", candle.low)
                )
                .foregroundStyle(candle.close >= candle.open ? AppColors.green : AppColors.red)
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date.formatted(.dateTime.hour()))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(priceModel.formatPrice(usd: doubleValue))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .frame(height: height)
    }
}
