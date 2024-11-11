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
    let prices: [Price]
    let intervalSecs: Double
    var timeframeMins: Double = 30
    let height: CGFloat

    @State private var candles: [CandleData] = []
    @State private var transparentCandle: CandleData?

    init(prices: [Price], intervalSecs: Double, timeframeMins: Double? = 30, maxCandleWidth: CGFloat = 10, height: CGFloat = 330) {
        self.prices = prices
        self.intervalSecs = intervalSecs > 0 ? intervalSecs : 1;
        self.timeframeMins = timeframeMins ?? 30
        self.height = height
    }

    private var filteredPrices: [Price] {
        let filteredPrices = filterPrices(prices: prices, timeframeSecs: timeframeMins * 60)
        return filteredPrices
    }
    
    private func filterPrices(prices: [Price], timeframeSecs: Double) -> [Price] {
        let cutoffDate = Date().addingTimeInterval(-timeframeSecs)
        if let firstValidIndex = prices.firstIndex(where: { $0.timestamp >= cutoffDate }) {
            return Array(prices[firstValidIndex...])
        }
        
        // Fallback: return last 2 prices if no prices are within timeframe
        return Array(prices.suffix(2))
    }
    private func updateCandles() {
        if prices.isEmpty { return }
        let startTime = prices.first!.timestamp
        let groupedPrices = Dictionary(grouping: prices) { price in
            floor(price.timestamp.timeIntervalSince1970 / intervalSecs) * intervalSecs
        }

        let cutoffTime = Date().addingTimeInterval(-timeframeMins * 60)
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

        // Add transparent candle if needed
        let timeframeStart = Date().addingTimeInterval(-Double(timeframeMins) * 60)
        if let firstCandle = candles.first, firstCandle.start > timeframeStart {
            transparentCandle = CandleData(
                start: timeframeStart,
                end: firstCandle.start,
                open: firstCandle.open,
                close: firstCandle.open,
                high: firstCandle.open,
                low: firstCandle.open
            )
        } else {
            transparentCandle = nil
        }
    }

    var body: some View {
        Chart {
            transparentCandleMark
            candleMarks
            highLowLines
            lastCandleAnnotation
        }
        .chartYAxis(content: yAxisConfig)
        .chartXAxis(content: xAxisConfig)
        .chartYScale(domain: yDomain)
        .frame(height: height)
        .onAppear(perform: updateCandles)
        .onChange(of: prices) { _ in updateCandles() }
    }

    private var transparentCandleMark: (some ChartContent)? {
        if let transparentCandle = transparentCandle {
            RectangleMark(
                xStart: .value("Start", transparentCandle.start),
                xEnd: .value("End", transparentCandle.end),
                yStart: .value("Open", transparentCandle.open),
                yEnd: .value("Close", transparentCandle.close)
            )
            .foregroundStyle(Color.gray.opacity(0.3))
        } else {
            nil
        }
    }

    private var candleMarks: (some ChartContent)? {
        ForEach(candles, id: \.start) { candle in
            RectangleMark(
                xStart: .value("Start", candle.start + 10),
                xEnd: .value("End", candle.end - 10),
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

    private var lastCandleAnnotation: (some ChartContent)? {
        if let lastCandle = candles.last {
            PointMark(
                x: .value("Middle", lastCandle.start.addingTimeInterval(intervalSecs / 2)),
                y: .value("Close", lastCandle.close)
            )
            .symbolSize(10)
            .foregroundStyle(AppColors.white.opacity(0.7))
            .annotation(position: lastCandle.close >= lastCandle.open ? .top : .bottom, spacing: 4) {
                PillView(
                    value: priceModel.formatPrice(lamports: lastCandle.close),
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
            AxisValueLabel {
                if let intValue = value.as(Int.self) {
                    Text(priceModel.formatPrice(lamports: intValue))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    private func xAxisConfig() -> some AxisContent {
        AxisMarks(values: .stride(by: .minute, count: Int(floor(timeframeMins / 4)))) { value in
            AxisValueLabel(format: .dateTime.hour().minute())
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var yDomain: ClosedRange<Int> {
        if prices.isEmpty { return 0...100 }

        var pricesWithPurchase = prices
        
        let minPrice = pricesWithPurchase.min { $0.price < $1.price }?.price ?? 0
        let maxPrice = pricesWithPurchase.max { $0.price < $1.price }?.price ?? 100
        let range = maxPrice - minPrice
        let padding = Int(Double(range) * 0.25)
        
        return (minPrice - padding)...(maxPrice + padding)
    }
}

struct CandleData {
    let start: Date
    let end: Date
    let open: Int
    let close: Int
    let high: Int
    let low: Int
}
