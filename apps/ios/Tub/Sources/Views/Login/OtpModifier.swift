//
//  OtpModifier.swift
//  Tub
//
//  Created by Henry on 10/31/24.
//

//  (Original code by ifeanyichukwu  on 03/02/2023)

import Combine
import SwiftUI

struct OtpModifer: ViewModifier {
    @Binding var pin: String

    var isFocused: Bool  // Add this property
    var textLimit = 1

    func limitText(_ upper: Int) {
        if pin.count > upper {
            self.pin = String(pin.prefix(upper))
        }
    }

    //MARK -> BODY
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .onReceive(Just(pin)) { _ in limitText(textLimit) }
            .frame(width: 45, height: 45)
            .background(Color.clear.cornerRadius(5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        isFocused ? .tubBuyPrimary : .tubBuyPrimary.opacity(0.5),
                        lineWidth: isFocused ? 4 : 1
                    )
            )
    }
}
