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
	let animate: Bool
    let rawPrices: [Price]
    let height: CGFloat
    let purchaseData: PurchaseData?

    @State private var prices: [Price] = []

    let initialPointSize: Double = 35
    @State private var pointSize: Double = 35

    private let xAxisPadding: Double = Timespan.live.seconds * 0.1

    init(rawPrices: [Price], purchaseData: PurchaseData? = nil, animate: Bool, height: CGFloat = 330) {
		self.rawPrices = rawPrices
        self.purchaseData = purchaseData
		self.animate = animate
        self.height = height
    }

    private func updatePrices() {
        let cutoffTime = Date().addingTimeInterval(-Timespan.live.seconds)
        prices = rawPrices.sorted(by: { $0.timestamp < $1.timestamp }).filter { $0.timestamp > cutoffTime }
    }

    private var xDomain: ClosedRange<Date> {
        guard let firstDate = prices.first?.timestamp,
            let lastDate = prices.last?.timestamp
        else { return Date()...Date() }

        return firstDate...(lastDate.addingTimeInterval(xAxisPadding))
    }

    private var yDomain: ClosedRange<Double> {
        if prices.isEmpty { return 0...100 }

        var pricesWithPurchase = prices
        if let data = purchaseData {
            let price = Price(timestamp: data.timestamp, priceUsd: data.priceUsd)
            pricesWithPurchase.append(price)
        }

        let minPriceUsd = pricesWithPurchase.min { $0.priceUsd < $1.priceUsd }?.priceUsd ?? 0
        let maxPriceUsd = pricesWithPurchase.max { $0.priceUsd < $1.priceUsd }?.priceUsd ?? 100
        let range = maxPriceUsd - minPriceUsd
        let padding = range * 0.10

        return (minPriceUsd - padding)...(maxPriceUsd + padding)
    }

    var body: some View {
        Chart {
            ForEach(prices.dropLast()) { price in
                LineMark(
                    x: .value("Date", price.timestamp),
                    y: .value("Price", price.priceUsd)
                )
                .foregroundStyle(.tubBuyPrimary.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.cardinal(tension: 0.8))
            }

            if let currentPrice = prices.last, prices.count >= 2 {
                LineMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .foregroundStyle(.tubBuyPrimary.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.cardinal(tension: 0.8))
                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .foregroundStyle(.tubBuyPrimary)
                .symbolSize(initialPointSize)
                .annotation(position: .top, spacing: 6) {
                    if let priceUsd = purchaseData?.priceUsd {
                        let purchaseIncrease = (currentPrice.priceUsd - priceUsd) / priceUsd
                        Text("\(purchaseIncrease >= 0 ? "+" : "")\(String(format: "%.1f%%", purchaseIncrease * 100))")
                            .foregroundStyle(.tubText.opacity(0.9))
                            .padding(8)
                            .background(.tubSellSecondary)
                            .font(.sfRounded(size: .xxs))
                            .fontWeight(.bold)
                            .clipShape(Capsule())
                    }
                }

                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .foregroundStyle(.tubBuySecondary)
                .symbolSize(pointSize)
            }

            if let purchaseData {
                // Calculate x position as max of purchase time and earliest chart time
                let xPosition = max(
                    purchaseData.timestamp,
                    prices.first?.timestamp ?? purchaseData.timestamp
                )

                // Add horizontal dashed line
                RuleMark(y: .value("Purchase Price", purchaseData.priceUsd))
                    .foregroundStyle(.tubSellPrimary.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))

                PointMark(
                    x: .value("Date", xPosition),  // Updated x-value
                    y: .value("Price", purchaseData.priceUsd)
                )
                .foregroundStyle(.tubSellPrimary)
                .symbolSize(initialPointSize)
                .symbol(.circle)
                .annotation(position: .bottom, spacing: 2) {
                    VStack(spacing: -2.5) {
                        // Add triangle
                        Image(systemName: "triangle.fill")
                            .resizable()
                            .frame(width: 12, height: 6)
                            .foregroundStyle(.tubSellPrimary)

                        Text("B")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.tubSellPrimary)
                            .font(.sfRounded(size: .sm))
                            .fontWeight(.bold)
                            .clipShape(Circle())
                    }
                }
            }
        }
        // The animated visual "swipe-chart-glitch" prob occurs here. It happens
        //	because when we scrollTokenList view to focus on a new token,
        //	we immediately replace the token price data previously plotted
        //	by the graph with completely different token price data: the visual
        //	glitch occurs when all of the plotted data changes at once.
        .if(animate) { view in
            view.animation(.linear(duration: PRICE_UPDATE_INTERVAL), value: prices)
        }
        .chartYScale(domain: yDomain)
        .chartXScale(domain: xDomain)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .onAppear {
            updatePrices()
            withAnimation(.easeInOut(duration: 2).repeatForever()) {
                pointSize = 150
            }
        }
        .onChange(of: rawPrices) {
            updatePrices()
        }
    }
}

struct PillView: View {
    let value: String
    let color: Color
    let foregroundColor: Color
    let fontSize: Font.TwSize

    var body: some View {
        Text(value)
            .font(.caption)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .font(.sfRounded(size: fontSize))
            .fontWeight(.bold)
            .clipShape(Capsule())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject var priceModel = {
            let model = SolPriceModel.shared
            spoofPriceModelData(model)
            return model
        }()

        // Add state variables for controls
        @State private var isDark = false
        @State private var showPurchaseData = true

        var purchaseData: PurchaseData {
            PurchaseData(
                tokenId: "",
                timestamp: spoofPrices[20].timestamp,
                amountUsdc: 1000,
                priceUsd: spoofPrices[20].priceUsd
            )
        }

        var body: some View {
            VStack {
                // Add control buttons
                VStack {
                    Text("Modifiers")
                    PrimaryButton(text: "Toggle Purchase Data") {
                        showPurchaseData.toggle()
                    }
                    PrimaryButton(text: "Toggle Dark Mode") {
                        isDark.toggle()
                    }
                }
                .padding(16)
                .background(.tubBuySecondary)

                Spacer().frame(height: 50)

                // Update ChartView to use the controls
                ChartView(
					rawPrices: spoofPrices,
                    purchaseData: showPurchaseData ? purchaseData : nil,
					animate: false,
                    height: 330
                )
                .border(.red)
                .environmentObject(priceModel)
                .preferredColorScheme(isDark ? .dark : .light)
            }
        }
    }

    return PreviewWrapper()
}
