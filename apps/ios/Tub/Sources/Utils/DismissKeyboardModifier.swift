//
//  DismissKeyboardModifier.swift
//  Tub
//
//  Created by yixintan on 11/9/24.
//

import SwiftUI

/**
 * This view modifier is responsible for dismissing the keyboard when the user taps on the screen.
*/
struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
