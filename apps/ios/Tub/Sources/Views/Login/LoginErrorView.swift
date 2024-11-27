//
//  LoginErrorView.swift
//  Tub
//
//  Created by Henry on 11/12/24.
//

import SwiftUI

struct LoginErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void
    let logoutAction: (() -> Void)?

    init(errorMessage: String, retryAction: @escaping () -> Void, logoutAction: (() -> Void)? = nil) {
        self.errorMessage = errorMessage
        self.retryAction = retryAction
        self.logoutAction = logoutAction
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Connection Error")
                .font(.sfRounded(size: .xl, weight: .bold))

            Text(errorMessage)
                .font(.sfRounded(size: .base))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: retryAction) {
                Text("Try Again")
                    .font(.sfRounded(size: .lg, weight: .semibold))
                    .foregroundStyle(.tubText)
                    .padding(14)
                    .background(.tubBuyPrimary)
                    .cornerRadius(26)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .foregroundStyle(.tubBuyPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.tubError, lineWidth: 2)
                .background(.tubError.opacity(0.05))
        )
    }
}

#Preview("Light") {
    LoginErrorView(
        errorMessage: "Unable to connect to your account. Please check your connection and try again.",
        retryAction: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoginErrorView(
        errorMessage: "Unable to connect to your account. Please check your connection and try again.",
        retryAction: {}
    ).preferredColorScheme(.dark)
}
