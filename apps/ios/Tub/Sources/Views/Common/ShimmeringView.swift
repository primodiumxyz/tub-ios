//
//  ShimmeringView.swift
//  Tub
//
//  Created by Henry on 11/9/24.
//

import SwiftUI

struct ShimmeringView: ViewModifier {
    @State private var phase: CGFloat = 0
    let opacity: Double
    
    init(opacity: Double = 0.1) {
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Color.white
                        .opacity(opacity)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * 2)
                                .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                        )
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering(opacity: Double = 0.1) -> some View {
        modifier(ShimmeringView(opacity: opacity))
    }
}

