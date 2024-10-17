//
//  CandleChartView.swift
//  Tub
//
//  Created by Henry on 10/17/24.
//

import SwiftUI
import Charts

struct CandleChartView: View {
    let prices: [Price]
    let intervalSecs: Double
    let timeframeMins: Int?

    @State private var candles: [CandleData] = []

    init(prices: [Price], intervalSecs: Double, timeframeMins: Int? = nil) {
        self.prices = prices
        self.intervalSecs = intervalSecs
        self.timeframeMins = timeframeMins
    }

    private func updateCandles() {
        if prices.isEmpty { return }
        let startTime = prices.first!.timestamp
        let groupedPrices = Dictionary(grouping: prices) { price in
            floor((price.timestamp.timeIntervalSince1970 - startTime.timeIntervalSince1970) / intervalSecs) * intervalSecs
        }

        let cutoffTime = Date().addingTimeInterval(-Double(timeframeMins ?? 30) * 60)
        let filteredGroupedPrices = groupedPrices.filter { key, values in
            values.first!.timestamp >= cutoffTime
        }

        let sortedKeys = filteredGroupedPrices.keys.sorted()
        candles = sortedKeys.enumerated().compactMap { (index, key) -> CandleData? in
            let values = filteredGroupedPrices[key]!
            let sortedValues = values.sorted(by: { $0.timestamp < $1.timestamp })
            let open = sortedValues.first?.price ?? 0
            let high = sortedValues.map { $0.price }.max() ?? 0
            let low = sortedValues.map { $0.price }.min() ?? 0
            
            if index + 1 < sortedKeys.count {
                let nextKey = sortedKeys[index + 1]
                let nextValues = filteredGroupedPrices[nextKey]!
                let nextOpen = nextValues.sorted(by: { $0.timestamp < $1.timestamp }).first?.price ?? 0
                
                print(nextKey)
                return CandleData(
                    start: Date(timeIntervalSince1970: key),
                    end: Date(timeIntervalSince1970: nextKey),
                    open: open,
                    close: nextOpen,
                    high: high,
                    low: low
                )
            } else {
                // Skip the last candle
                return nil
            }
        }
    }

    var body: some View {
        Chart {
            candleMarks
            highLowLines
            lastCandleAnnotation
        }
        .chartYAxis(content: yAxisConfig)
        .chartYScale(domain: .automatic)
        .frame(width: .infinity, height: 350)
        .onAppear(perform: updateCandles)
        .onChange(of: prices) { _ in updateCandles() }
    }

    private var candleMarks: some ChartContent {
        ForEach(candles, id: \.start) { candle in
            RectangleMark(
                xStart: .value("Start", candle.start),
                xEnd: .value("End", candle.end),
                yStart: .value("Open", candle.open),
                yEnd: .value("Close", candle.close)
            )
            .foregroundStyle(candle.close > candle.open ? Color.green : Color.red)
        }
    }

    private var highLowLines: some ChartContent {
        ForEach(candles, id: \.start) { candle in
            RuleMark(
                x: .value("Center", candle.start.addingTimeInterval(intervalSecs / 2)),
                yStart: .value("High", candle.high),
                yEnd: .value("Low", candle.low)
            )
            .foregroundStyle(candle.close > candle.open ? Color.green.opacity(0.5) : Color.red.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1))
        }
    }

//    @ViewBuilder
    private var lastCandleAnnotation: (some ChartContent)?? {
        if let lastCandle = candles.last {
            PointMark(
                x: .value("Middle", lastCandle.start.addingTimeInterval(intervalSecs / 2)),
                y: .value("Close", lastCandle.close)
            )
            .symbolSize(10)
            .foregroundStyle(AppColors.white.opacity(0.7))
            .annotation(position: .top, spacing: 4) {
                PillView(
                    value: String(format: "%.2f SOL", lastCandle.close),
                    color: AppColors.white.opacity(0.7),
                    foregroundColor: AppColors.black
                )
            }
        } else {
            nil
        }
    }

    private func yAxisConfig() -> some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(.white.opacity(0.2))
            AxisValueLabel()
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

struct CandleData {
    let start: Date
    let end: Date
    let open: Double
    let close: Double
    let high: Double
    let low: Double
}

struct CandleChartView_Previews: PreviewProvider {
    static var previews: some View {
        CandleChartView(
            prices: [
                Price(timestamp: Date(), price: 100.0),
                Price(timestamp: Date().addingTimeInterval(86400), price: 105.0),
                Price(timestamp: Date().addingTimeInterval(172800), price: 102.0),
                Price(timestamp: Date().addingTimeInterval(259200), price: 110.0),
                Price(timestamp: Date().addingTimeInterval(345600), price: 114.0),
                Price(timestamp: Date().addingTimeInterval(432000), price: 109.0),
                Price(timestamp: Date().addingTimeInterval(518400), price: 109)
            ],
            intervalSecs: 86400, // 1 day interval
            timeframeMins: 60 * 24 * 7 // 7 days timeframe
        ).background(.black)
    }
}
