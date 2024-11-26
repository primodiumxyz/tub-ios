//
//  Chart.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import Charts
import Combine
import SwiftUI

struct ChartView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @Binding var animate: Bool
    let rawPrices: [Price]
    let height: CGFloat

    var purchasePriceUsd: Double? {
        if let purchaseData = userModel.purchaseData {
            return priceModel.lamportsToUsd(lamports: purchaseData.price)
        }
        else {
            return nil
        }
    }

    @State private var currentTime = Date().timeIntervalSince1970
    @State private var prices: [Price] = []

    init(prices: [Price], animate: Binding<Bool>, height: CGFloat = 330) {
        self.rawPrices = prices
        self._animate = animate
        self.height = height
    }

    private func updatePrices() {
        let dataPointCount = Int(Timespan.live.seconds / PRICE_UPDATE_INTERVAL)
        let startingIndex = rawPrices.count - dataPointCount
        prices = startingIndex < 0 ? rawPrices : Array(rawPrices[startingIndex...])
    }

    private var dashedLineColor: Color {
        guard let purchasePriceUsd,
            let currentPriceUsd = prices.last?.priceUsd
        else { return Color.white }
        if currentPriceUsd == purchasePriceUsd {
            return Color.white
        }
        return currentPriceUsd < purchasePriceUsd ? Color("redLight") : Color("greenLight")
    }

    private var change: Double? {
        guard let purchasePriceUsd,
            let currentPriceUsd = prices.last?.priceUsd
        else { return nil }
        return (currentPriceUsd - purchasePriceUsd)
    }

    private var yDomain: ClosedRange<Double> {
        if prices.isEmpty { return 0...100 }

        var pricesWithPurchase = prices
        if let data = userModel.purchaseData, let purchasePriceUsd {
            let price = Price(timestamp: data.timestamp, priceUsd: purchasePriceUsd)
            pricesWithPurchase.append(price)
        }

        let minPriceUsd = pricesWithPurchase.min { $0.priceUsd < $1.priceUsd }?.priceUsd ?? 0
        let maxPriceUsd = pricesWithPurchase.max { $0.priceUsd < $1.priceUsd }?.priceUsd ?? 100
        let range = maxPriceUsd - minPriceUsd
        let padding = range * 0.10

        return (minPriceUsd - padding)...(maxPriceUsd + padding)
    }
    private var xDomain: ClosedRange<Date> {
        let min = Date(timeIntervalSinceNow: -Timespan.live.seconds - 1)
        var padding = 1.0
        if let currentPrice = prices.last?.priceUsd {
            let pillContent = priceModel.formatPrice(usd: abs(currentPrice), maxDecimals: 9, minDecimals: 2)
            padding = Double(pillContent.count) * 1.5
        }

        let max = Date(timeIntervalSinceNow: padding)
        return min...max
    }

    var body: some View {
        Chart {
            ForEach(prices.dropLast()) { price in
                LineMark(
                    x: .value("Date", price.timestamp),
                    y: .value("Price", price.priceUsd)
                )
                .foregroundStyle(Color("aquaBlue").opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.cardinal(tension: 0.8))
            }

            if let currentPrice = prices.last, prices.count >= 2 {
                LineMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .foregroundStyle(Color("aquaBlue").opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.cardinal(tension: 0.8))

                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .foregroundStyle(Color.white.opacity(0.5))

                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .annotation(position: .top, spacing: 4) {
                    if userModel.purchaseData?.timestamp == currentPrice.timestamp {
                        EmptyView()
                    }
                    else {
                        PillView(
                            value:
                                "\(priceModel.formatPrice(usd: abs(currentPrice.priceUsd), maxDecimals: 9, minDecimals: 2))",
                            color: dashedLineColor,
                            foregroundColor: Color.black
                        )
                    }
                }
            }

            if let data = userModel.purchaseData, let purchasePriceUsd {
                // Calculate x position as max of purchase time and earliest chart time
                let xPosition = max(
                    data.timestamp,
                    prices.first?.timestamp ?? data.timestamp
                )

                // Add horizontal dashed line
                RuleMark(y: .value("Purchase Price", purchasePriceUsd))
                    .foregroundStyle(Color("pink").opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))

                PointMark(
                    x: .value("Date", xPosition),  // Updated x-value
                    y: .value("Price", purchasePriceUsd)
                )
                .foregroundStyle(Color("pink"))
                .symbolSize(100)
                .symbol(.circle)
                .annotation(position: .bottom, spacing: 0) {
                    PillView(
                        value: "\(priceModel.formatPrice(usd: purchasePriceUsd, maxDecimals: 9, minDecimals: 2))",
                        color: Color("pink").opacity(0.8),
                        foregroundColor: Color.white
                    )
                }
            }
        }
        .if(animate) { view in view.animation(.linear(duration: PRICE_UPDATE_INTERVAL), value: prices)
        }
        .chartYScale(domain: yDomain)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .onChange(of: rawPrices) {
            updatePrices()
        }
    }
}

struct PillView: View {
    let value: String
    let color: Color
    let foregroundColor: Color

    var body: some View {
        Text(value)
            .font(.caption)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .font(.sfRounded(size: .lg))
            .fontWeight(.bold)
            .clipShape(Capsule())
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
