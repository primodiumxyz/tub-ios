//
//  SignInWithApple.swift
//  Tub
//
//  Created by Henry on 10/30/24.
//

import AuthenticationServices
import PrivySDK
import SwiftUI

struct SIWA: UIViewRepresentable {

    typealias UIViewType = ASAuthorizationAppleIDButton

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        return ASAuthorizationAppleIDButton()
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
    }
}

struct SignInWithApple: View {

    var body: some View {
        SIWA()
    }

}

#Preview {
    SignInWithApple()
}
