//
//  LoginWithEmailView.swift
//  Tub
//
//  Created by Henry on 10/31/24.
//

import SwiftUI
import PrivySDK

struct SignInWithEmailView: View {
    @State private var email = ""
    @State private var otpCode = ""
    @State private var showOTPInput = false
    @State private var showEmailInput = false
    @State private var otpFlowState: OtpFlowState = .initial
    
    private func handleEmailLogin() {
        Task {
            let otpSent = await privy.email.sendCode(to: email)
            if otpSent {
                showOTPInput = true
            }
        }
    }
    
    private func verifyOTP() {
        Task {
            do {
                let _ = try await privy.email.loginWithCode(otpCode, sentTo: email)
            } catch {
                debugPrint("OTP verification error: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if showEmailInput {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .autocapitalization(.none)
                
                if showOTPInput {
                    TextField("Enter OTP", text: $otpCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .keyboardType(.numberPad)
                    
                    Button(action: verifyOTP) {
                        Text("Verify OTP")
                            .font(.sfRounded(size: .base, weight: .semibold))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(AppColors.primaryPurple)
                            .cornerRadius(26)
                    }.padding(.horizontal)
                } else {
                    Button(action: handleEmailLogin) {
                        Text("Continue")
                            .font(.sfRounded(size: .base, weight: .semibold))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(AppColors.primaryPurple)
                            .cornerRadius(26)
                    }.padding(.horizontal)
                }
            } else {
                Button(action: { showEmailInput = true }) {
                    Text("Continue with Email")
                        .font(.sfRounded(size: .base, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(26)
                }.padding(.horizontal)
            }
        }.onAppear {
            privy.email.setOtpFlowStateChangeCallback { state in
                otpFlowState = state
            }
        }
    }
}
