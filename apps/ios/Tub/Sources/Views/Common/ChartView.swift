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
    
    var color = Color(red: 0.43, green: 0.97, blue: 0.98)
    
    private var dashedLineColor: Color {
        guard prices.count >= 2 else { return .white }
        let currentPrice = prices.last!.price
        let previousPrice = prices[prices.count - 2].price
        if(currentPrice == previousPrice) {
            return .white
        }
        return currentPrice < previousPrice ? .red : .green
    }
    
    private var percentageChange: Double {
        guard prices.count >= 2 else { return 0 }
        let currentPrice = prices.last!.price
        let previousPrice = prices[prices.count - 2].price
        return (currentPrice - previousPrice) / previousPrice * 100
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
                .foregroundStyle(color.opacity(0.8)) // Neon blue line
                .shadow(color: color, radius: 3, x: 2, y: 2)
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
            
            if let currentPrice = prices.last {
                RuleMark(x: .value("Date", currentPrice.timestamp))
                    .foregroundStyle(dashedLineColor.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
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
                    PillView(percentage: percentageChange, color: dashedLineColor)
                }
            }

            if let purchasePrice = closestPurchasePrice {
                PointMark(
                    x: .value("Date", purchasePrice.timestamp),
                    y: .value("Price", purchasePrice.price)
                )
                .foregroundStyle(pink)
                .symbolSize(100)
                .symbol(.circle)
                
                // Add speech bubble
                .annotation(position: .bottom, spacing: 0) {
                    VStack(spacing: -3) {
                        Triangle()
                            .fill(pink)
                            .frame(width: 20, height: 10)
                            .rotationEffect(Angle(degrees: 180))
//                            .offset(y: -1) // Slight offset to connect with the circle
                        ZStack {
                            Circle()
                                .fill(pink)
                                .frame(width: 50, height: 50)
                            Text("\(purchasePrice.price, specifier: "%.2f")")
                                .foregroundColor(.white)
                                .font(.sfRounded(size: .xs, weight: .bold))
                        }
                        
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 200)
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
            ], purchaseTime: Date().addingTimeInterval(172800)
        )
    }
}

struct PillView: View {
    let percentage: Double
    let color: Color
    
    var body: some View {
        Text(String(format: "%.0f%%", percentage))
            .font(.caption)
            .foregroundColor(.black)
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
