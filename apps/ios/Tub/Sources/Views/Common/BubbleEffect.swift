//
//  BubbleEffect.swift
//  Tub
//
//  Created by yixintan on 11/11/24.
//

import Foundation
import SwiftUI

struct Bubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
}

struct BubbleEffect: View {
    @State private var bubbles: [Bubble] = []
    @Binding var isActive: Bool

    let bubbleCount = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(bubbles) { bubble in
                    Image("Bubble")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color("Tub/Primary").opacity(1.0))
                        .frame(width: 30, height: 30)
                        .scaleEffect(bubble.scale)
                        .position(bubble.position)
                        .opacity(bubble.opacity)
                        .blur(radius: 1.0)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                if isActive {
                    createBubbles(in: geometry)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    createBubbles(in: geometry)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    private func createBubbles(in geometry: GeometryProxy) {
        bubbles = []
        for _ in 0..<bubbleCount {
            let randomX = CGFloat.random(in: 0...geometry.size.width)
            let randomStartY = CGFloat.random(in: geometry.size.height...(geometry.size.height + 250))

            let bubble = Bubble(
                position: CGPoint(x: randomX, y: randomStartY),
                scale: CGFloat.random(in: 0.4...2.0),
                opacity: 1.0
            )

            bubbles.append(bubble)

            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: Double.random(in: 2.0...4.0))) {
                    if let index = bubbles.firstIndex(where: { $0.id == bubble.id }) {
                        let randomEndY = CGFloat.random(in: -100...0)
                        bubbles[index].position.y = randomEndY
                        bubbles[index].opacity = 0
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isActive = false
            bubbles = []
        }
    }
}
