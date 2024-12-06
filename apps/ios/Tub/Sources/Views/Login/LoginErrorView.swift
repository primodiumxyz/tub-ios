//
//  LoginErrorView.swift
//  Tub
//
//  Created by Henry on 11/12/24.
//

import SwiftUI

struct LoginErrorView: View {
    let title: String
    let errorMessage: String
    let retryAction: () async -> Void
    let logoutAction: (() -> Void)?
    @State var retrying = false

    init(
        title: String = "Something went wrong. ",
        errorMessage: String,
        retryAction: @escaping () async -> Void,
        logoutAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.errorMessage = errorMessage
        self.retryAction = retryAction
        self.logoutAction = logoutAction
    }
    
    func handleRetry() {
        retrying = true
        Task {
            await retryAction()
            await MainActor.run {
                retrying = false
            }
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text(title)
                .font(.sfRounded(size: .xl, weight: .bold))

            Text(errorMessage)
                .font(.sfRounded(size: .base))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            PrimaryButton(text: "Try again", maxWidth: 200, loading: retrying, action: handleRetry
                
            )
        }
        .padding(8)
        .background(Color(UIColor.systemBackground))
        .foregroundStyle(.tubBuyPrimary)
        .frame(maxWidth: 350)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.tubError, lineWidth: 2)
                .background(.tubError.opacity(0.1))
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
