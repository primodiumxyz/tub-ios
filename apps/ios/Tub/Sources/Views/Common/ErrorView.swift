//
//  ErrorView.swift
//  Tub
//
//  Created by Henry on 11/12/24.
//

import SwiftUI

struct ErrorView: View {
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
                .foregroundStyle(.tubError)

            Text(errorMessage)
                .font(.sfRounded(size: .base))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            PrimaryButton(text: "Try again", maxWidth: 200, loading: retrying, action: handleRetry)
        }
        .padding(8)
        .foregroundStyle(.tubBuyPrimary)
        .frame(maxWidth: 350, maxHeight: .infinity)
    }
}

#Preview("Light") {
    ErrorView(
        errorMessage: "Unable to connect to your account. Please check your connection and try again.",
        retryAction: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ErrorView(
        errorMessage: "Unable to connect to your account. Please check your connection and try again.",
        retryAction: {}
    ).preferredColorScheme(.dark)
}
