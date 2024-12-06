//
//  CandleChartView.swift
//  Tub
//
//  Created by Henry on 10/17/24.
//

import Charts
import Combine
import SwiftUI

struct CandleChartView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    let rawCandles: [CandleData]
    let timeframeMins: Double
    let height: CGFloat
    @State private var currentTime = Date().timeIntervalSince1970

    let animate: Bool
    @State private var timerCancellable: Cancellable?
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 0.1, on: .main, in: .common)

    init(
        candles: [CandleData],
        animate: Bool,
        timeframeMins: Double = 30,
        height: CGFloat = 330
    ) {
        self.rawCandles = candles
        self.animate = animate
        self.timeframeMins = timeframeMins
        self.height = height
    }

    private var candles: [CandleData] {
        let cutoffTime = currentTime - (timeframeMins * 60)
        if let firstIndex = rawCandles.firstIndex(where: {
            $0.start.timeIntervalSince1970 >= cutoffTime
        }) {
            return Array(rawCandles.suffix(from: firstIndex))
        }
        return rawCandles
    }

    private var yDomain: ClosedRange<Double> {
        if candles.isEmpty { return 0...100 }

        let minPrice = candles.min { $0.low < $1.low }?.low ?? 0
        let maxPrice = candles.max { $0.high < $1.high }?.high ?? 100
        let range = maxPrice - minPrice
        let padding = range * 0.10

        return (minPrice - padding)...(maxPrice + padding)
    }

    private var xDomain: ClosedRange<Date> {
        if candles.isEmpty {
            return Date().addingTimeInterval(-timeframeMins * 60)...Date()
        }

        let endTime = candles.last?.end ?? Date()
        let startTime = endTime.addingTimeInterval(-timeframeMins * 60)
        return startTime...endTime
    }

    var body: some View {
        Chart {
            ForEach(candles) { candle in
                // Candlestick body
                RectangleMark(
                    x: .value("Time", candle.start),
                    yStart: .value("Open", candle.open),
                    yEnd: .value("Close", candle.close)
                )
                .foregroundStyle(candle.close >= candle.open ? Color.green : Color.red)

                // High-Low line
                RuleMark(
                    x: .value("Time", candle.start),
                    yStart: .value("High", candle.high),
                    yEnd: .value("Low", candle.low)
                )
                .foregroundStyle(candle.close >= candle.open ? Color.green : Color.red)
                .opacity(0.5)
            }
        }
        .if(animate) { view in view.animation(.linear(duration: PRICE_UPDATE_INTERVAL), value: candles)
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .conditionalModifier(condition: false) { chart in
            chart.animation(.easeInOut(duration: PRICE_UPDATE_INTERVAL), value: candles)
        }
        .chartXAxis(content: xAxisConfig)
        .chartYAxis(content: yAxisConfig)
        .frame(height: height)
        .onAppear {
            timerCancellable = timer.connect()
        }
        .onDisappear {
            timerCancellable?.cancel()
        }

    }
    private func yAxisConfig() -> some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(.tubBuyPrimary.opacity(0.2))
            AxisValueLabel {
                if let doubleValue = value.as(Double.self) {
                    Text(priceModel.formatPrice(usd: doubleValue, maxDecimals: 6))
                        .foregroundStyle(.tubBuyPrimary.opacity(0.5))
                }
            }
        }
    }

    private func xAxisConfig() -> some AxisContent {
        AxisMarks(values: .stride(by: .minute, count: 4)) { value in
            // show the first 6 labels (after that it gets cutoff
            if value.index <= 6 {
                AxisValueLabel(format: .dateTime.hour().minute())
                    .foregroundStyle(.tubBuyPrimary.opacity(0.5))
            }
        }
    }
}
