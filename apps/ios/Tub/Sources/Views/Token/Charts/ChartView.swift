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
    
    init(prices: [Price], timeframeSecs: Double = 90.0, purchaseTime: Date? = nil, purchaseAmount: Int? = nil) {
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
    
    private var yDomain: ClosedRange<Int> {
        if prices.isEmpty { return 0...100 }
        
        let minPrice = prices.min { $0.price < $1.price }?.price ?? 0
        let maxPrice = prices.max { $0.price < $1.price }?.price ?? 100
        let range = maxPrice - minPrice
        let padding = Int(Double(range) * 0.15)
        
        return (minPrice - padding)...(maxPrice + padding)
    }
    
    var body: some View {
        Chart {
            ForEach(prices) { price in
                LineMark(
                    x: .value("Date", price.timestamp),
                    y: .value("Price", price.price)
                )
                .foregroundStyle(AppColors.aquaBlue.opacity(0.8))
                .shadow(color: AppColors.aquaBlue, radius: 3, x: 2, y: 2)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom) 
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
                        EmptyView()
                    } else {
                        PillView(
                            value: "\(priceModel.formatPrice(lamports: abs(currentPrice.price)))",
                             color: dashedLineColor,
                             foregroundColor: AppColors.black
                        )
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
        .chartYScale(domain: yDomain)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .frame(width: .infinity, height: 330)
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
