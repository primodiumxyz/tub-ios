//
//  SignInWithApple.swift
//  Tub
//
//  Created by Henry on 10/30/24.
//

import SwiftUI
import PrivySDK
import AuthenticationServices

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
        SIWA().frame(maxWidth: 300, maxHeight: 60).cornerRadius(26)
    }
    
}

#Preview {
    SignInWithApple()
}
