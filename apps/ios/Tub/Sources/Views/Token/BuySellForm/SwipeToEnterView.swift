//
//  SwipeToEnterView.swift
//  Tub
//
//  Created by Henry on 9/30/24.
//

import SwiftUI

struct SwipeToEnterView: View {
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var isSuccess = false
    var onUnlock: () -> Void
    var text: String
    var disabled: Bool
    var size: CGFloat = 80

    init(text: String = "slide to unlock", onUnlock: @escaping () -> Void, disabled: Bool = false) {
        self.text = text
        self.onUnlock = onUnlock
        self.disabled = disabled
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.black.opacity(0.3))
                // Centered text with chevrons
                HStack {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Text(text)
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .foregroundColor(Color.white)
                    Spacer()
                    // Add three right-facing chevrons
                    HStack(spacing: 2) {
                        ForEach(0..<3) { i in
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.white)
                                .font(.system(size: 14, weight: .bold))
                                .opacity(Double(i) * 0.15 + 0.5)
                        }
                    }
                    .padding(.trailing, 20)
                    Spacer()
                }

                // Slider thumb
                ZStack {
                    Circle()
                        .fill(Color("purple"))
                        .frame(width: size - 20, height: size - 20)

                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(Color.white)
                        .fontWeight(.bold)
                        .font(.system(size: 20))  // Increase the size by 50%
                }
                .offset(x: offset + 10)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard !disabled else { return }
                            isDragging = true
                            offset = min(max(0, value.translation.width), geometry.size.width - size)
                        }
                        .onEnded { _ in
                            guard !disabled else { return }
                            isDragging = false
                            if offset > (geometry.size.width - size - 10) {
                                withAnimation {
                                    offset = geometry.size.width - size
                                }
                                isSuccess = true
                                onUnlock()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    withAnimation {
                                        offset = 0
                                        isSuccess = false
                                    }
                                }
                            }
                            else {
                                withAnimation {
                                    offset = 0
                                }
                            }
                        }
                )

            }
            .frame(height: size)
            .clipShape(RoundedRectangle(cornerRadius: size / 2))
            .opacity(disabled ? 0.5 : 1)
        }
    }
}

#Preview {
    VStack {
        SwipeToEnterView(text: "Swipe to confirm") {
            print("Unlocked!")
        }
        SwipeToEnterView(text: "Swipe to proceed", disabled: true) {
            print("This won't be called when disabled")
        }
    }
    .frame(height: 220)
    .padding()
}
