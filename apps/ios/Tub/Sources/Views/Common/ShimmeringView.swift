//
//  ShimmeringView.swift
//  Tub
//
//  Created by Henry on 11/9/24.
//

import SwiftUI

struct ShimmeringView: View {
    @State private var phase: CGFloat = 0
    let opacity: Double
    let cornerRadius: CGFloat

    init(opacity: Double = 0.1, cornerRadius: CGFloat = 8) {
        self.opacity = opacity
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.white.opacity(opacity), Color.clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geometry.size.width * 2)
                .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
        }
        .mask(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// Update the ViewModifier to use the new ShimmeringView
struct ShimmeringModifier: ViewModifier {
    let opacity: Double
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(ShimmeringView(opacity: opacity, cornerRadius: cornerRadius))
    }
}

extension View {
    func shimmering(opacity: Double = 0.1, cornerRadius: CGFloat = 8) -> some View {
        modifier(ShimmeringModifier(opacity: opacity, cornerRadius: cornerRadius))
    }
}
