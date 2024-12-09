//
//  SFRounded.swift
//  Tub
//
//  Created by Henry on 9/30/24.
//

import SwiftUI

extension Font {
    // Add an enum for Tailwind-like font sizes
    enum TwSize: CGFloat {
        case xxs = 10
        case xs = 12
        case sm = 14
        case base = 16
        case lg = 18
        case xl = 20
        case xl2 = 24
        case xl3 = 30
        case xl4 = 36
        case xl5 = 48
        case xl6 = 60
    }

    // Update the font function to use the new TailwindSize enum and adjust kerning
    static func sfRounded(size: TwSize = .base, weight: Font.Weight = .regular) -> Font {
        let baseSize = size.rawValue
        let screenHeight = UIScreen.main.bounds.height
        
        // iPhone SE height is around 667, iPhone 16 Pro Max is 1024
        let minHeight: CGFloat = 667
        let maxHeight: CGFloat = 1024
        
        // Scale font size based on screen height
        let scale = min(max(screenHeight / maxHeight, 0.9), 1.0)
        let scaledSize = baseSize * scale
        
        return Font.system(size: scaledSize, weight: weight, design: .rounded)
    }
}
