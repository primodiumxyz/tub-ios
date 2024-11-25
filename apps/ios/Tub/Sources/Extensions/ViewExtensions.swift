//
//  ViewExtensions.swift
//  Tub
//
//  Created by JJ on 11/20/24.
//

import SwiftUI

extension View {
    // Allows modifiers to be coonditionally applied to views
    @ViewBuilder
    func conditionalModifier<V: View>(condition: Bool, modifier: (Self) -> V) -> some View {
        if condition {
            modifier(self)
        } else {
            self
        }
    }
}
