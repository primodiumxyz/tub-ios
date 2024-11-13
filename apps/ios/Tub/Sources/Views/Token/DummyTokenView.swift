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
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
                .frame(width: 100, height: 30)
                .padding(.bottom, 2)
                .shimmering()
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
                .frame(width: 200, height: 40)
                .padding(.bottom, 2)
                .shimmering()
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
                .frame(width: 160, height: 14)
                .padding(.bottom, 8)
                .shimmering()
            // Chart
             RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
                .frame(width: .infinity, height: 300)
                .padding(.bottom, 18)
                .shimmering()
            Spacer()
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
                .frame(width: .infinity, height: 100)
                .padding(.bottom, 2)
                .shimmering()
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
        .foregroundColor(AppColors.white)
    }
}
import SwiftUI
import Charts



