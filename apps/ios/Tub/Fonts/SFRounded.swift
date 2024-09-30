//
//  SFRounded.swift
//  Tub
//
//  Created by Henry on 9/30/24.
//

import SwiftUI

extension Font {
    static func sfRounded(size: CGFloat = 14, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .rounded)
    }
}
