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
    
    init(width: CGFloat = .infinity, height: CGFloat = .infinity, opacity: Double = 0.3, cornerRadius : CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.opacity = opacity
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.1))
            .frame(width: width, height: height)
            .shimmering(opacity: opacity)
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

