//
//  LoadingBox.swift
//  Tub
//
//  Created by Henry on 11/18/24.
//

import SwiftUI

struct LoadingBox: View {
    let width: CGFloat
    let height: CGFloat
    let opacity: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat = .infinity, height: CGFloat = .infinity, opacity: Double = 0.3, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.opacity = opacity
    }

    var body: some View {
        if width == .infinity && height == .infinity {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.1))
                .shimmering(opacity: opacity)
        } else if width == .infinity {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.1))
                .frame(maxWidth: width, minHeight: height, maxHeight: height)
                .shimmering(opacity: opacity)
        } else if height == .infinity {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.1))
                .frame(minWidth: width, maxWidth: width, maxHeight: height)
                .shimmering(opacity: opacity)
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.1))
                .frame(width: width, height: height)
                .shimmering(opacity: opacity)
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        LoadingBox(width: 200, height: 40)
        LoadingBox(width: 300, height: 100, cornerRadius: 12)
        LoadingBox(width: 300, height: 100, opacity: 1, cornerRadius: 12)
    }
    .padding()
    .background(Color.black)
}
