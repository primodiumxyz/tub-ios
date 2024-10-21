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
    var timeframeMins: Double = 30

    @State private var candles: [CandleData] = []
    @State private var transparentCandle: CandleData?

    init(prices: [Price], intervalSecs: Double, timeframeMins: Double? = 30, maxCandleWidth: CGFloat = 10) {
        self.prices = prices
        self.intervalSecs = intervalSecs
        self.timeframeMins = timeframeMins ?? 30
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
        .chartYScale(domain: .automatic)
        .frame(height: 350)
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

    private func xAxisConfig() -> some AxisContent {
        AxisMarks(values: .stride(by: .minute, count: Int(floor(timeframeMins / 4)))) { value in
            AxisValueLabel(format: .dateTime.hour().minute())
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
                 Price(timestamp: Date().addingTimeInterval(-1800), price: 106.0),
                Price(timestamp: Date().addingTimeInterval(-1500), price: 107.5),
                Price(timestamp: Date().addingTimeInterval(-1200), price: 108.0),
                Price(timestamp: Date().addingTimeInterval(-900), price: 109.0),
                Price(timestamp: Date().addingTimeInterval(-600), price: 110.5),
                Price(timestamp: Date().addingTimeInterval(-300), price: 112.0),
                Price(timestamp: Date().addingTimeInterval(-120), price: 114.0)
            ],
            intervalSecs: 300, // 5-minute interval
            timeframeMins: 60 
        ).background(.black)
    }
}
