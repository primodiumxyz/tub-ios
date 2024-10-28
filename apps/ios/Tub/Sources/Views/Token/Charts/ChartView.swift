//
//  Chart.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import SwiftUI
import Charts

struct ChartView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    let prices: [Price]
    let timeframeSecs: Double
    let purchaseTime: Date?
    let purchaseAmount: Int
    
    init(prices: [Price], timeframeSecs: Double, purchaseTime: Date? = nil, purchaseAmount: Int? = nil) {
        self.prices = prices
        self.timeframeSecs = timeframeSecs
        self.purchaseTime = purchaseTime
        self.purchaseAmount = purchaseAmount ?? 0
    }
    
    @State private var currentTime = Date().timeIntervalSince1970
    
    private var dashedLineColor: Color {
        guard let purchasePrice = closestPurchasePrice?.price,
              let currentPrice = prices.last?.price else { return AppColors.white }
        if currentPrice == purchasePrice {
            return AppColors.white
        }
        return currentPrice < purchasePrice ? AppColors.lightRed : AppColors.lightGreen
    }
    
    private var change: Int? {
        guard let purchasePrice = closestPurchasePrice?.price,
              let currentPrice = prices.last?.price else { return nil }
        return (currentPrice - purchasePrice)
    }
    
    private var closestPurchasePrice: Price? {
        guard let purchaseTime = purchaseTime else { return nil }
        return prices.min(by: { abs($0.timestamp.timeIntervalSince(purchaseTime)) < abs($1.timestamp.timeIntervalSince(purchaseTime)) })
    }
    
    private var filteredPrices: [Price] {
        // Use currentTime in the calculation to trigger updates
        let filteredPrices = filterPrices(prices: prices, timeframeSecs: timeframeSecs, currentTime: currentTime)
        return filteredPrices
    }
    
    private func interpolatePrice(firstPoint: Price, secondPoint: Price, atTimestamp timestamp: TimeInterval) -> Price {
        let timeSpan = secondPoint.timestamp.timeIntervalSince(firstPoint.timestamp)
        let priceSpan = Double(secondPoint.price - firstPoint.price)
        let slope = priceSpan / timeSpan
        
        let timeDiff = timestamp - firstPoint.timestamp.timeIntervalSince1970
        let interpolatedPrice = Int(Double(firstPoint.price) + slope * timeDiff)
        
        return Price(timestamp: Date(timeIntervalSince1970: timestamp), price: interpolatedPrice)
    }
    
    private func filterPrices(prices: [Price], timeframeSecs: Double, currentTime: TimeInterval) -> [Price] {
        if(prices.count < 2) {
           return prices 
        }
        let cutoffDate = currentTime - timeframeSecs
        var filteredPrices = prices.filter { $0.timestamp.timeIntervalSince1970 >= cutoffDate }
        
        if filteredPrices.count < 2 {
            filteredPrices = Array(prices.suffix(2))
        } else if filteredPrices.count >= 2 {
            // Find the final filtered point and first unfiltered point
            let firstUnfilteredPoint = filteredPrices.first!
            if let firstUnfilteredIndex = prices.firstIndex(where: { $0.timestamp.timeIntervalSince1970 >= cutoffDate }), firstUnfilteredIndex > 0
            {
                // Interpolate the price at the cutoff date
                let interpolatedPoint = interpolatePrice(firstPoint: firstUnfilteredPoint,
                                                         secondPoint: prices[firstUnfilteredIndex - 1],
                                                         atTimestamp: cutoffDate)
                filteredPrices.insert(interpolatedPoint, at: 0)
            } else {
                filteredPrices.insert(firstUnfilteredPoint, at: 0)
            }
        }
        
        // Append a price at the current time with the most recent price value
        if let lastPrice = prices.last {
            let currentPrice = Price(timestamp: Date(timeIntervalSince1970: currentTime), price: lastPrice.price)
            filteredPrices.append(currentPrice)
        }
        
        return filteredPrices
    }
    
    var body: some View {
        Chart {
            ForEach(filteredPrices) { price in
                LineMark(
                    x: .value("Date", price.timestamp),
                    y: .value("Price", price.price)
                )
                .foregroundStyle(AppColors.aquaBlue.opacity(0.8))
                .shadow(color: AppColors.aquaBlue, radius: 3, x: 2, y: 2)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom) 
            }
            
            if let currentPrice = filteredPrices.last, filteredPrices.count >= 2 {
                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.price)
                )
                .foregroundStyle(.white.opacity(0.5)) // Transparent fill
                .symbolSize(100)
                
                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.price)
                )
                .annotation(position: .top, spacing: 4) {
                    if closestPurchasePrice?.timestamp == currentPrice.timestamp {
                        EmptyView()
                    } else {
                    PillView(value:
                                "\(priceModel.formatPrice(lamports: abs(currentPrice.price)))",
                             color: dashedLineColor,
                             foregroundColor: AppColors.black)
                    }
                }
            }
            
            if let purchasePrice = closestPurchasePrice {
                // Add horizontal dashed line
                RuleMark(y: .value("Purchase Price", purchasePrice.price))
                    .foregroundStyle(AppColors.primaryPink.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                
                PointMark(
                    x: .value("Date", purchasePrice.timestamp),
                    y: .value("Price", purchasePrice.price)
                )
                .foregroundStyle(AppColors.primaryPink)
                .symbolSize(100)
                .symbol(.circle)
                
                .annotation(position: .bottom, spacing: 0) {
                    PillView(
                        value: "\(priceModel.formatPrice(lamports: purchasePrice.price))",
                        color: AppColors.primaryPink.opacity(0.8), foregroundColor: AppColors.white)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .second, count: Int(floor(timeframeSecs / 2)))) { value in
                AxisValueLabel(format: .dateTime.hour().minute())
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.white.opacity(0.2))
                AxisValueLabel()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text(priceModel.formatPrice(lamports: intValue))
                            .foregroundStyle(.white)
                            .font(.sfRounded(size: .xs, weight: .regular))
                    }
                }
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .chartYScale(domain: .automatic)
        .frame(width: .infinity, height: 350)
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
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
