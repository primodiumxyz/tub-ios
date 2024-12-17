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

// Singleton manager to control bubble animations globally
class BubbleManager: ObservableObject {
    static let shared = BubbleManager()
    
    @Published var isActive: Bool = false
    @Published private(set) var bubbles: [Bubble] = []
    private var animationTimer: Timer?
    
    private init() {}
    
    func trigger(bubbleCount: Int = 50, duration: Double = 2.5) {
        // Reset state
        isActive = true
        bubbles = []
        
        // Auto-stop after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isActive = false
            self?.bubbles = []
            self?.animationTimer?.invalidate()
            self?.animationTimer = nil
        }
    }
    
    func addBubble(in geometry: GeometryProxy) {
        let randomX = CGFloat.random(in: 0...geometry.size.width)
        let randomStartY = geometry.size.height + 200
        
        let bubble = Bubble(
            position: CGPoint(x: randomX, y: randomStartY),
            scale: CGFloat.random(in: 0.6...2.5),
            opacity: 0.8
        )
        
        bubbles.append(bubble)
        
        let duration = Double.random(in: 3.0...6.0)
        let endY = 1000.0
        // Animate the bubble
        DispatchQueue.main.asyncAfter(deadline: .now()) {
           
            withAnimation(.easeOut(duration: duration)) {
                if let index = self.bubbles.firstIndex(where: { $0.id == bubble.id }) {
                    self.bubbles[index].position.y = -endY
                    self.bubbles[index].opacity = 0.0
                }
            }
            
        }
                // Remove the bubble after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) {
            self.bubbles.removeAll(where: { $0.id == bubble.id })
        }

    }
}

// View modifier to add bubble effect to any view
struct BubbleEffectModifier: ViewModifier {
    @StateObject private var bubbleManager = BubbleManager.shared
    let bubbleCount: Int
    
    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { geometry in
                ZStack {
                    ForEach(bubbleManager.bubbles) { bubble in
                        Image("Bubble")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.tubBuyPrimary)
                            .frame(width: 30, height: 30)
                            .scaleEffect(bubble.scale)
                            .position(x: bubble.position.x, y: bubble.position.y)
                            .opacity(bubble.opacity)
                            .blur(radius: 1.0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: bubbleManager.isActive) { _, isActive in
                    if isActive {
                        for _ in 0..<bubbleCount {
                            bubbleManager.addBubble(in: geometry)
                        }
                    }
                }
            }
        }
    }
}

// Extension to make the bubble effect easily applicable to any view
extension View {
    func bubbleEffect(bubbleCount: Int = 50) -> some View {
        modifier(BubbleEffectModifier(bubbleCount: bubbleCount))
    }
}

#Preview("BubbleEffect") {
    VStack {
        Text("Hello, World!")
        PrimaryButton(text: "Trigger") {
            BubbleManager.shared.trigger()
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .bubbleEffect()
    .background(.tubBuySecondary)
    .border(.red)

}
