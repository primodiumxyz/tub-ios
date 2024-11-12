//
//  DummyTokenView.swift
//  Tub
//
//  Created by Henry on 11/11/24.
//

import SwiftUI

struct DummyTokenView: View {
    let height: CGFloat
    
    var prices: [Price] = {
        let now = Date()
        return [
            Price(timestamp: now.addingTimeInterval(-60), price: Int(1)),
            Price(timestamp: now.addingTimeInterval(-45), price: Int(4)),
            Price(timestamp: now.addingTimeInterval(-30), price: Int(3)),
            Price(timestamp: now.addingTimeInterval(-15), price: Int(6)),
            Price(timestamp: now, price: Int(10)),
        ]
    }()
    
    var body: some View {
        // Token Info
        VStack(alignment: .leading, spacing: 4) {
            Text("Loading...")
                .font(.sfRounded(size: .lg, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            Text("$0.00")
                .font(.sfRounded(size: .xl4, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            // Chart
            ChartView(prices: prices)
                .frame(height: 300)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
        .foregroundColor(AppColors.white)
        .blur(radius: 4)
    }
}
import SwiftUI
import Charts



