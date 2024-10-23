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
    let purchaseAmount: Int
    
    init(prices: [Price], purchaseTime: Date? = nil, purchaseAmount: Int? = nil) {
        self.prices = prices
        self.purchaseTime = purchaseTime
        self.purchaseAmount = purchaseAmount ?? 0
    }
    
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
    
    var body: some View {
        Chart {
            ForEach(prices) { price in
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
                        PillView(value: "\(PriceFormatter.formatPrice(lamports: currentPrice.price)) SOL", color: AppColors.white,
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
                        value: "\(PriceFormatter.formatPrice(lamports: purchasePrice.price)) SOL",
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
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text(PriceFormatter.formatPrice(lamports: intValue))
                            .foregroundStyle(.white)
                            .font(.sfRounded(size: .xs, weight: .regular))
                    }
                }
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .chartYScale(domain: .automatic)
        .frame(height: 350)
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
