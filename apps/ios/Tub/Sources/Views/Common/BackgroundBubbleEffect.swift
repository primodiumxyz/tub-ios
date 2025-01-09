//
//  BackgroundBubbleEffect.swift
//  Tub
//
//  Created by yixintan on 12/21/24.
//

import SwiftUI

// Separate manager for background bubbles
class BackgroundBubbleManager: ObservableObject {
    static let shared = BackgroundBubbleManager()
    
    @Published var isActive: Bool = false
    @Published private(set) var bubbles: [Bubble] = []
    
    private init() {}
    
    func setupBubbles(in geometry: GeometryProxy) {
        // Clear existing bubbles
        bubbles = []
        
        // Create more bubbles with larger sizes
        for _ in 0..<12 {  
            let randomX = CGFloat.random(in: 0...geometry.size.width)
            let randomY = CGFloat.random(in: 0...geometry.size.height)
            
            let bubble = Bubble(
                position: CGPoint(x: randomX, y: randomY),
                scale: CGFloat.random(in: 0.8...2.0),  
                opacity: 0.2  
            )
            
            bubbles.append(bubble)
            
            // Start floating animation for this bubble
            animateBubble(at: bubbles.count - 1, in: geometry)
        }
    }
    
    private func animateBubble(at index: Int, in geometry: GeometryProxy) {
        let floatDistance: CGFloat = 30  
        let currentY = bubbles[index].position.y
        let duration = Double.random(in: 2.0...3.0)  
        
        // Animate up
        withAnimation(.easeInOut(duration: duration).repeatForever()) {
            bubbles[index].position.y = currentY - floatDistance
        }
    }
}

// Separate modifier for background bubbles
struct BackgroundBubbleEffectModifier: ViewModifier {
    @StateObject private var bubbleManager = BackgroundBubbleManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            // Background bubbles
            GeometryReader { geometry in
                ZStack {
                    ForEach(bubbleManager.bubbles) { bubble in
                        Image("Bubble")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.tubBuyPrimary)
                            .frame(width: 50, height: 50)  
                            .scaleEffect(bubble.scale)
                            .position(x: bubble.position.x, y: bubble.position.y)
                            .opacity(bubble.opacity)
                            .blur(radius: 2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    bubbleManager.setupBubbles(in: geometry)
                }
            }
        }
    }
}

// Extension for easy application
extension View {
    func backgroundBubbleEffect() -> some View {
        modifier(BackgroundBubbleEffectModifier())
    }
} 