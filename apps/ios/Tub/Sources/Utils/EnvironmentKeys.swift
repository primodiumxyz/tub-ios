//
//  EnvironmentKeys.swift
//  Tub
//
//  Created by yixintan on 12/5/24.
//

import SwiftUI

struct ScreenSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var screenSize: CGSize {
        get { self[ScreenSizeKey.self] }
        set { self[ScreenSizeKey.self] = newValue }
    }
} 