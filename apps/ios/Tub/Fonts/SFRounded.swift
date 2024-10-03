//
//  SFRounded.swift
//  Tub
//
//  Created by Henry on 9/30/24.
//

import SwiftUI

extension Font {
    // Add an enum for Tailwind-like font sizes
    enum TailwindSize: CGFloat {
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
    static func sfRounded(size: TailwindSize = .base, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size.rawValue, weight: weight, design: .rounded)
    }
}
