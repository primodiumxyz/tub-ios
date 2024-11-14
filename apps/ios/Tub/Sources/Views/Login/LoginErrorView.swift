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
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.red)
            
            Text("Connection Error")
                .font(.sfRounded(size: .xl, weight: .bold))
            
            Text(errorMessage)
                .font(.sfRounded(size: .base))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button(action: retryAction) {
                    Text("Try Again")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(26)
                }
                
                Button(action: {
                    privy.logout()
                }) {
                    Text("Logout")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(AppColors.red, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .foregroundStyle(.white)
    }
}

#Preview {
    LoginErrorView(
        errorMessage: "Unable to connect to your account. Please check your connection and try again.",
        retryAction: {}
    )
}

