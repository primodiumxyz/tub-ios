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
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.red)

            Text("Connection Error")
                .font(.sfRounded(size: .xl, weight: .bold))

            Text(errorMessage)
                .font(.sfRounded(size: .base))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: retryAction) {
                Text("Try Again")
                    .font(.sfRounded(size: .lg, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(.accent)
                    .cornerRadius(26)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .foregroundStyle(.primary)
    }
}

#Preview {
    LoginErrorView(
        errorMessage: "Unable to connect to your account. Please check your connection and try again.",
        retryAction: {}
    )
}
