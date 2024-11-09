//
//  LoadingView.swift
//  Tub
//
//  Created by Henry on 10/8/24.
//
import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .font(.sfRounded(size: .base))
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(.white)
    }
}


struct LoadingPrice: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.05))
            .frame(width: 120, height: 32)
            .shimmering(opacity: 0.1)
    }
}

struct LoadingPriceChange: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.05))
            .frame(width: 80, height: 20)
            .shimmering(opacity: 0.1)
    }
}

struct LoadingChart: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.03))
            .frame(height: 350)
            .shimmering(opacity: 0.08)
    }
}
