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
    let rawPrices: [Price]
    let timeframeSecs: Double
    let purchaseData: PurchaseData?
    let height: CGFloat
    
    init(prices: [Price], timeframeSecs: Double = 90.0, purchaseData: PurchaseData? = nil, height: CGFloat = 330) {
        self.rawPrices = prices
        self.timeframeSecs = timeframeSecs
        self.purchaseData = purchaseData
        self.height = height
    }
    
    @State private var currentTime = Date().timeIntervalSince1970
    
    private var dashedLineColor: Color {
        guard let purchasePrice = purchaseData?.price,
              let currentPrice = prices.last?.price else { return AppColors.white }
        if currentPrice == purchasePrice {
            return AppColors.white
        }
        return currentPrice < purchasePrice ? AppColors.lightRed : AppColors.lightGreen
    }
    
    private var change: Int? {
        guard let purchasePrice = purchaseData?.price,
              let currentPrice = prices.last?.price else { return nil }
        return (currentPrice - purchasePrice)
    }
    
    private var yDomain: ClosedRange<Int> {
        if prices.isEmpty { return 0...100 }

        var pricesWithPurchase = prices
        if let data = purchaseData {
            let price = Price(timestamp: data.timestamp, price: data.price)
            pricesWithPurchase.append(price)
        }
        
        let minPrice = pricesWithPurchase.min { $0.price < $1.price }?.price ?? 0
        let maxPrice = pricesWithPurchase.max { $0.price < $1.price }?.price ?? 100
        let range = maxPrice - minPrice
        let padding = Int(Double(range) * 0.25)
        
        return (minPrice - padding)...(maxPrice + padding)
    }
    
    private var prices: [Price] {
        let cutoffTime = currentTime - timeframeSecs
        if let firstValidIndex = rawPrices.firstIndex(where: { $0.timestamp.timeIntervalSince1970 >= cutoffTime }) {
            return Array(rawPrices[firstValidIndex...])
        }
        return rawPrices
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
//                .interpolationMethod(.catmullRom) 
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
                    if purchaseData?.timestamp == currentPrice.timestamp {
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
            
            if let data = purchaseData {
                // Calculate x position as max of purchase time and earliest chart time
                let xPosition = max(
                    data.timestamp,
                    prices.first?.timestamp ?? data.timestamp
                )

                // Add horizontal dashed line
                RuleMark(y: .value("Purchase Price", data.price))
                    .foregroundStyle(AppColors.primaryPink.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                
                PointMark(
                    x: .value("Date", xPosition),  // Updated x-value
                    y: .value("Price", data.price)
                )
                .foregroundStyle(AppColors.primaryPink)
                .symbolSize(100)
                .symbol(.circle)
                
                .annotation(position: .bottom, spacing: 0) {
                    PillView(
                        value: "\(priceModel.formatPrice(lamports: data.price))",
                        color: AppColors.primaryPink.opacity(0.8), foregroundColor: AppColors.white)
                }
            }
        }
        .chartYScale(domain: yDomain)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .frame(width: .infinity, height: height)
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
