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
    let cutoffTime = Date.now.addingTimeInterval(-timeframeMins * 60)
    if let firstIndex = rawCandles.firstIndex(where: {
      $0.start > cutoffTime
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

    let endTime = Date.now
    let rightMargin = timeframeMins * 60 * 0.1
    let startTime = endTime.addingTimeInterval(-60 - timeframeMins * 60)
    return startTime...endTime.addingTimeInterval(rightMargin)
  }

  private var emptyTickHeight: Double {
    let range = yDomain.upperBound - yDomain.lowerBound
    return range * 0.002  // 0.2% of the total range
  }

  var body: some View {
    Chart {
      ForEach(candles) { candle in
        if !candle.hasTrades {
          // For empty candles, show a small horizontal line or tiny candle
          RectangleMark(
            x: .value("Time", candle.start),
            yStart: .value("Price", candle.close - emptyTickHeight),
            yEnd: .value("Price", candle.close + emptyTickHeight)
          )
          .foregroundStyle(Color.green)
        } else {
          // Normal candle body
          RectangleMark(
            x: .value("Time", candle.start),
            yStart: .value("Open", candle.open),
            yEnd: .value("Close", candle.close)
          )
          .foregroundStyle(candle.close >= candle.open ? Color.green : Color.red)

          // High-Low line only for non-empty candles
          RuleMark(
            x: .value("Time", candle.start),
            yStart: .value("High", candle.high),
            yEnd: .value("Low", candle.low)
          )
          .foregroundStyle(candle.close >= candle.open ? Color.green : Color.red)
          .opacity(0.5)
        }
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
    AxisMarks(values: .stride(by: .minute, count: 10)) { value in
      AxisValueLabel(format: .dateTime.hour().minute())
        .foregroundStyle(.tubBuyPrimary.opacity(0.5))
    }
  }
}

#Preview {
  @Previewable @StateObject var priceModel = {
    let model = SolPriceModel.shared
    spoofPriceModelData(model)
    return model
  }()

  let candles = [
    // add 10 more candles
    CandleData(
      start: Date().addingTimeInterval(-120 * 60), end: Date().addingTimeInterval(-110 * 60),
      open: 100, close: 105, high: 110, low: 90, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-110 * 60), end: Date().addingTimeInterval(-100 * 60),
      open: 105, close: 110, high: 115, low: 95, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-100 * 60), end: Date().addingTimeInterval(-90 * 60),
      open: 110, close: 115, high: 120, low: 100, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-90 * 60), end: Date().addingTimeInterval(-80 * 60),
      open: 115, close: 120, high: 125, low: 105, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-80 * 60), end: Date().addingTimeInterval(-70 * 60),
      open: 120, close: 125, high: 130, low: 110, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-70 * 60), end: Date().addingTimeInterval(-60 * 60),
      open: 125, close: 130, high: 135, low: 115, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-60 * 60), end: Date().addingTimeInterval(-50 * 60),
      open: 130, close: 135, high: 140, low: 120, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-50 * 60), end: Date().addingTimeInterval(-40 * 60),
      open: 135, close: 140, high: 145, low: 125, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-40 * 60), end: Date().addingTimeInterval(-30 * 60),
      open: 140, close: 145, high: 150, low: 130, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-30 * 60), end: Date().addingTimeInterval(-20 * 60),
      open: 145, close: 150, high: 155, low: 135, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-20 * 60), end: Date().addingTimeInterval(-10 * 60),
      open: 105, close: 110, high: 115, low: 95, volume: 100, hasTrades: true),
    CandleData(
      start: Date().addingTimeInterval(-10 * 60), end: Date().addingTimeInterval(-0 * 60),
      open: 110, close: 115, high: 120, low: 100, volume: 100, hasTrades: true),
  ]
  CandleChartView(candles: candles, animate: true, timeframeMins: 120)
    .environmentObject(priceModel)
}
