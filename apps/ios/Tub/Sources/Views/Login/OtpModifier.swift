//
//  OtpModifier.swift
//  Tub
//
//  Created by Henry on 10/31/24.
//

//
//  OtpTextFieldView.swift
//  SchChat
//
//  Created by ifeanyichukwu  on 03/02/2023.
//

import Combine
import SwiftUI

struct OtpModifer: ViewModifier {

    @Binding var pin: String

    var isFocused: Bool  // Add this property
    var textLimt = 1

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
            .onReceive(Just(pin)) { _ in limitText(textLimt) }
            .frame(width: 45, height: 45)
            .background(Color.primary.cornerRadius(5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        isFocused ? Color("pink") : .secondary,
                        lineWidth: isFocused ? 4 : 1
                    )
            )
    }
}
