//
//  Chart.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import SwiftUI
import Charts
import Combine

let UPDATE_INTERVAL = 0.08

struct ChartView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    let rawPrices: [Price]
    let height: CGFloat

    var purchasePriceUsd : Double? {
        if let purchaseData = userModel.purchaseData {
            return priceModel.lamportsToUsd(lamports: purchaseData.price)
        } else {
            return nil
        }
    }
    
    @State private var currentTime = Date().timeIntervalSince1970
        
    @State private var timerCancellable: Cancellable?
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: UPDATE_INTERVAL, on: .main, in: .common)
    
    init(prices: [Price], height: CGFloat = 330) {
        self.rawPrices = prices
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
    
    private func interpolatePrice(firstPoint: Price, secondPoint: Price, atTimestamp timestamp: TimeInterval) -> Price {
        let timeSpan = secondPoint.timestamp.timeIntervalSince(firstPoint.timestamp)
        let priceSpan = secondPoint.priceUsd - firstPoint.priceUsd
        let slope = priceSpan / timeSpan
        
        let timeDiff = timestamp - firstPoint.timestamp.timeIntervalSince1970
        let interpolatedPrice = firstPoint.priceUsd + slope * timeDiff
        
        return Price(timestamp: Date(timeIntervalSince1970: timestamp), priceUsd: interpolatedPrice)
    }
    
    private var prices: [Price] {
        let cutoffTime = currentTime - CHART_INTERVAL
        
        let firstIndex = rawPrices.firstIndex(where: { $0.timestamp.timeIntervalSince1970 >= cutoffTime })
        
        var filteredPrices = rawPrices
        if rawPrices.count >= 3, let firstIndex, firstIndex > 0 {
            filteredPrices = Array(filteredPrices.suffix(from: firstIndex))
            let interpolatedPoint = interpolatePrice(
                firstPoint: rawPrices[firstIndex - 1],
                secondPoint: rawPrices[firstIndex],
                atTimestamp: cutoffTime
            )
            filteredPrices.insert(interpolatedPoint, at: 0)
        }
        
        if let lastPrice = filteredPrices.last {
            let currentTimePoint = Price(
                timestamp: Date(timeIntervalSince1970: currentTime),
                priceUsd: lastPrice.priceUsd
            )
            filteredPrices.append(currentTimePoint)
        }
        
        if filteredPrices.count >= 2 {
            return filteredPrices
        }
        
        if rawPrices.count >= 2 {
            return Array(rawPrices.suffix(2))
        }
        
        return rawPrices
    }
    
    
    var body: some View {
        Chart {
            ForEach(prices.dropLast(1)) { price in
                LineMark(
                    x: .value("Date", price.timestamp),
                    y: .value("Price", price.priceUsd)
                )
                .foregroundStyle(AppColors.aquaBlue.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 3))
                .shadow(color: AppColors.aquaBlue, radius: 3, x: 2, y: 2)
                .interpolationMethod(.cardinal(tension: 0.8))
            }
            
            
            if let currentPrice = prices.last, prices.count >= 2 {
                LineMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .foregroundStyle(AppColors.aquaBlue.opacity(0.8))
                .shadow(color: AppColors.aquaBlue, radius: 3, x: 2, y: 2)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .foregroundStyle(.white.opacity(0.5))
                
                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.priceUsd)
                )
                .annotation(position: .top, spacing: 4) {
                    if userModel.purchaseData?.timestamp == currentPrice.timestamp {
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
            
            if let data = userModel.purchaseData, let purchasePriceUsd {
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
                        value: "\(priceModel.formatPrice(usd: purchasePriceUsd, maxDecimals: 9, minDecimals: 2))",
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
