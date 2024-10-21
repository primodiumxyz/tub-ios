//
//  Chart.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import SwiftUI
import Charts

struct ChartView: View {
    let prices: [Price]
    let purchaseTime: Date?
    let purchaseAmount: Double
    let timeframeSecs: Double?

    private var filteredPrices: [Price] {
        let cutoffTime = Date().addingTimeInterval(-(timeframeSecs ?? 30))
        return prices.filter { $0.timestamp >= cutoffTime }
    }
    
    init(prices: [Price], purchaseTime: Date? = nil, purchaseAmount: Double? = nil, timeframeSecs: Double? = 30) {
        self.prices = prices
        self.purchaseTime = purchaseTime
        self.purchaseAmount = purchaseAmount ?? 0.0
        self.timeframeSecs = timeframeSecs
    }
    
    private var dashedLineColor: Color {
        guard let purchasePrice = closestPurchasePrice?.price,
              let currentPrice = prices.last?.price else { return AppColors.white }
        if currentPrice == purchasePrice {
            return AppColors.white
        }
        return currentPrice < purchasePrice ? AppColors.lightRed : AppColors.lightGreen
    }
    
    private var change: Double? {
        guard let purchasePrice = closestPurchasePrice?.price,
              let currentPrice = prices.last?.price else { return nil }
        return (currentPrice - purchasePrice)
    }
    
    private var closestPurchasePrice: Price? {
        guard let purchaseTime = purchaseTime else { return nil }
        return prices.min(by: { abs($0.timestamp.timeIntervalSince(purchaseTime)) < abs($1.timestamp.timeIntervalSince(purchaseTime)) })
    }
    
    var body: some View {
        Chart {
            ForEach(filteredPrices) { price in
                LineMark(
                    x: .value("Date", price.timestamp),
                    y: .value("Price", price.price)
                )
                .foregroundStyle(AppColors.aquaBlue.opacity(0.8)) // Neon blue line
                .shadow(color: AppColors.aquaBlue, radius: 3, x: 2, y: 2)
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
            
            if let currentPrice = prices.last, prices.count >= 2 {
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
                        
                    }
                    else if change != nil {
                        PillView(value:
                                    "\(String(format: "%.2f%", abs(change! * purchaseAmount))) SOL",
                                 color: dashedLineColor,
                                 foregroundColor: AppColors.black)
                    } else {
                        PillView(value: "\(String(format: "%.2f%", currentPrice.price)) SOL", color: AppColors.white,
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
                        value: "\(String(format: "%.2f%", purchasePrice.price)) SOL",
                        color: AppColors.primaryPink.opacity(0.8), foregroundColor: AppColors.white)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.white.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.white)
                AxisValueLabel(format: .dateTime.month().day())
                    .foregroundStyle(.white)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.white.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .chartYScale(domain: .automatic)
        .frame(height: 350)
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(
            prices: [
                Price(timestamp: Date(), price: 100.0),
                Price(timestamp: Date().addingTimeInterval(86400), price: 105.0),
                Price(timestamp: Date().addingTimeInterval(172800), price: 102.0),
                Price(timestamp: Date().addingTimeInterval(259200), price: 110.0),
                Price(timestamp: Date().addingTimeInterval(345600), price: 114.0),
                Price(timestamp: Date().addingTimeInterval(432000), price: 109.0),
                Price(timestamp: Date().addingTimeInterval(518400), price: 109)
            ],
            purchaseTime: Date().addingTimeInterval(172800),
            timeframeSecs: 600000 // Example: Show data for the last 7 days
        )
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
