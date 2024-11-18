//
//  Chart.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import SwiftUI
import Charts
import Combine

struct ChartView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    let rawPrices: [Price]
    let timeframeSecs: Double
    let purchaseData: PurchaseData?
    let height: CGFloat
    
    var purchasePriceUsd : Double? {
        if let purchaseData {
            return priceModel.lamportsToUsd(lamports: purchaseData.price)
        } else {
            return nil
        }
    }
    @State private var currentTime = Date().timeIntervalSince1970
        
    @State private var timerCancellable: Cancellable?
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 0.1, on: .main, in: .common)
    
    init(prices: [Price], timeframeSecs: Double = CHART_INTERVAL, purchaseData: PurchaseData? = nil, height: CGFloat = 330) {
        self.rawPrices = prices
        self.timeframeSecs = timeframeSecs
        self.purchaseData = purchaseData
        self.height = height
    }
    
    private var dashedLineColor: Color {
        guard let purchasePriceUsd,
              let currentPriceUsd = prices.last?.priceUsd else { return AppColors.white }
        if currentPriceUsd == purchasePriceUsd {
            return AppColors.white
        }
        return currentPriceUsd < purchasePriceUsd ? AppColors.lightRed : AppColors.lightGreen
    }
    
    private var change: Double? {
        guard let purchasePriceUsd,
              let currentPriceUsd = prices.last?.priceUsd else { return nil }
        return (currentPriceUsd - purchasePriceUsd)
    }
    
    private var yDomain: ClosedRange<Double> {
        if prices.isEmpty { return 0...100 }
        
        var pricesWithPurchase = prices
        if let data = purchaseData, let purchasePriceUsd {
            let price = Price(timestamp: data.timestamp, priceUsd: purchasePriceUsd)
            pricesWithPurchase.append(price)
        }
        
        let minPriceUsd = pricesWithPurchase.min { $0.priceUsd < $1.priceUsd }?.priceUsd ?? 0
        let maxPriceUsd = pricesWithPurchase.max { $0.priceUsd < $1.priceUsd }?.priceUsd ?? 100
        let range = maxPriceUsd - minPriceUsd
        let padding = range * 0.10
        
        return (minPriceUsd - padding)...(maxPriceUsd + padding)
    }
    
    private var prices: [Price] {
        let cutoffTime = Date().addingTimeInterval(-timeframeSecs).timeIntervalSince1970
        if let firstValidIndex = rawPrices.firstIndex(where: { $0.timestamp.timeIntervalSince1970 >= cutoffTime }) {
            let slice = Array(rawPrices[firstValidIndex...])
            // If we have enough points in the time window, return them
            if slice.count >= 2 {
                return slice
            }
        }
        
        // If we don't have enough points in the time window,
        // return at least the last 2 points from rawPrices
        if rawPrices.count >= 2 {
            return Array(rawPrices.suffix(2))
        }
        
        return rawPrices
    }
    
    
    var body: some View {
        Chart {
            ForEach(prices) { price in
                LineMark(
                    x: .value("Date", price.timestamp),
                    y: .value("Price", price.priceUsd)
                )
                .foregroundStyle(AppColors.aquaBlue.opacity(0.8))
                .shadow(color: AppColors.aquaBlue, radius: 3, x: 2, y: 2)
                .lineStyle(StrokeStyle(lineWidth: 3))
//                .interpolationMethod(.catmullRom) 
            }
            
            if let currentPrice = prices.last, prices.count >= 2 {
                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .foregroundStyle(.white.opacity(0.5)) // Transparent fill
                .symbolSize(100)
                
                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .annotation(position: .top, spacing: 4) {
                    if purchaseData?.timestamp == currentPrice.timestamp {
                        EmptyView()
                    } else {
                        PillView(
                            value: "\(priceModel.formatPrice(usd: abs(currentPrice.priceUsd), maxDecimals: 9, minDecimals: 2))",
                             color: dashedLineColor,
                             foregroundColor: AppColors.black
                        )
                    }
                }
            }
            
            if let data = purchaseData, let purchasePriceUsd {
                // Calculate x position as max of purchase time and earliest chart time
                let xPosition = max(
                    data.timestamp,
                    prices.first?.timestamp ?? data.timestamp
                )

                // Add horizontal dashed line
                RuleMark(y: .value("Purchase Price", purchasePriceUsd))
                    .foregroundStyle(AppColors.primaryPink.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                
                PointMark(
                    x: .value("Date", xPosition),  // Updated x-value
                    y: .value("Price", purchasePriceUsd)
                )
                .foregroundStyle(AppColors.primaryPink)
                .symbolSize(100)
                .symbol(.circle)
                
                .annotation(position: .bottom, spacing: 0) {
                    PillView(
                        value: "\(priceModel.formatPrice(usd: purchasePriceUsd))",
                        color: AppColors.primaryPink.opacity(0.8), foregroundColor: AppColors.white)
                }
            }
        }
        .chartYScale(domain: yDomain)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .frame(width: .infinity, height: height)
        .onAppear {
            timerCancellable = timer.connect()
        }
        .onDisappear {
            timerCancellable?.cancel()
        }
        .onReceive(timer) { _ in
            currentTime = Date().timeIntervalSince1970
        }
    }
}

struct PillView: View {
    let value: String
    let color: Color
    let foregroundColor : Color
    
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
