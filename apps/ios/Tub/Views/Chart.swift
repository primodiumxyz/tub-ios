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
    
    var body: some View {
        Chart {
            ForEach(prices) { price in
                LineMark(
                    x: .value("Date", price.timestamp),
                    y: .value("Price", price.price)
                )
                .foregroundStyle(.blue.opacity(0.8)) // Neon blue line
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            
            // Add circle for current price point
            if let currentPrice = prices.last {
                PointMark(
                    x: .value("Date", currentPrice.timestamp),
                    y: .value("Price", currentPrice.price)
                )
                .foregroundStyle(.blue) // Transparent fill
                .symbolSize(100)
            }
            
            // Add dashed vertical line for current price
            if let currentPrice = prices.last {
                RuleMark(x: .value("Date", currentPrice.timestamp))
                    .foregroundStyle(.blue.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
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
        .padding()
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
                Price(timestamp: Date().addingTimeInterval(518400), price: 112.0)
            ]
        )
    }
}
