//
//  LoginWithEmailView.swift
//  Tub
//
//  Created by Henry on 10/31/24.
//

import PrivySDK
import SwiftUI

struct SignInWithEmailView: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @Binding var email: String  // Email passed from RegisterView
    @State private var loggingIn: Bool = false

    private func verifyOTP(otpCode: String) {
        Task {
            do {
                if self.loggingIn { return }
                self.loggingIn = true
                let _ = try await privy.email.loginWithCode(otpCode, sentTo: email)

                self.loggingIn = false
            }
            catch {
                notificationHandler.show(
                    error.localizedDescription,
                    type: .error
                )
                self.loggingIn = false
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Enter verification code")
                .font(.sfRounded(size: .lg, weight: .medium))
            OTPInputView(onComplete: verifyOTP)
        }
        .frame(maxHeight: .infinity)
        .background(Gradients.cardBgGradient)
        .dismissKeyboardOnTap()
    }
}
