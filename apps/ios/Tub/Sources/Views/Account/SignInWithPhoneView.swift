//
//  SignInWithPhoneView.swift
//  Tub
//
//  Created by Henry on 10/31/24.
//
import SwiftUI
import PrivySDK

struct SignInWithPhoneView: View {
    @State private var phoneNumber = ""
    @State private var otpCode = ""
    @State private var showOTPInput = false
    @State private var showPhoneInput = false
    @State private var otpFlowState: OtpFlowState = .initial
    
    private func handlePhoneLogin() {
        Task {
            let otpSent = await privy.sms.sendCode(to: phoneNumber)
            if otpSent {
                showOTPInput = true
            }
        }
    }
    
    private func verifyOTP() {
        Task {
            do {
                let _ = try await privy.sms.loginWithCode(otpCode, sentTo: phoneNumber)
            } catch {
                debugPrint("OTP verification error: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if showPhoneInput {
                TextField("Phone Number", text: $phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .keyboardType(.phonePad)
                
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
                    Button(action: handlePhoneLogin) {
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
                Button(action: { showPhoneInput = true }) {
                    Text("Continue with Phone")
                        .font(.sfRounded(size: .base, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(26)
                }.padding(.horizontal)
            }
        }.onAppear {
            privy.sms.setOtpFlowStateChangeCallback { state in
                otpFlowState = state
            }
        }
    }
}
