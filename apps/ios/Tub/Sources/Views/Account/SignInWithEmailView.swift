//
//  LoginWithEmailView.swift
//  Tub
//
//  Created by Henry on 10/31/24.
//

import SwiftUI
import PrivySDK

struct SignInWithEmailView: View {
    @EnvironmentObject private var errorHandler: ErrorHandler
    @Binding var email: String // Email passed from RegisterView
    @State private var showOTPInput = false
    @State private var otpFlowState: OtpFlowState = .initial
    @FocusState private var pinFocusState: FocusPin?
    @State private var pinOne = ""
    @State private var pinTwo = ""
    @State private var pinThree = ""
    @State private var pinFour = ""
    @State private var pinFive = ""
    @State private var pinSix = ""
    
    private var otpCode: String {
        pinOne + pinTwo + pinThree + pinFour + pinFive + pinSix
    }
    
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
                errorHandler.show(error)
            }
        }
    }
    
    private func handlePaste(_ pastedText: String, for pin: Binding<String>) {
        let cleaned = pastedText.filter { $0.isNumber }
        if cleaned.count == 6 {
            let chars = Array(cleaned)
            pinOne = String(chars[0])
            pinTwo = String(chars[1])
            pinThree = String(chars[2])
            pinFour = String(chars[3])
            pinFive = String(chars[4])
            pinSix = String(chars[5])
            verifyOTP()
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Enter verification code")
                .font(.sfRounded(size: .lg, weight: .medium))
                .foregroundColor(AppColors.white)
            
            HStack(spacing: 15) {
                TextField("", text: $pinOne)
                    .modifier(OtpModifer(pin: $pinOne))
                    .onChange(of: pinOne) { newVal in
                        if newVal.count > 1 {
                            handlePaste(newVal, for: $pinOne)
                        } else if newVal.count == 1 {
                            pinFocusState = .pinTwo
                        }
                    }
                    .focused($pinFocusState, equals: .pinOne)
                
                TextField("", text: $pinTwo)
                    .modifier(OtpModifer(pin: $pinTwo))
                    .onChange(of: pinTwo) { newVal in
                        if newVal.count == 0 {
                            pinFocusState = .pinOne
                        } else if newVal.count == 1 {
                            pinFocusState = .pinThree
                        }
                    }
                    .focused($pinFocusState, equals: .pinTwo)
                
                TextField("", text: $pinThree)
                    .modifier(OtpModifer(pin: $pinThree))
                    .onChange(of: pinThree) { newVal in
                        if newVal.count == 0 {
                            pinFocusState = .pinTwo
                        } else if newVal.count == 1 {
                            pinFocusState = .pinFour
                        }
                    }
                    .focused($pinFocusState, equals: .pinThree)
                
                TextField("", text: $pinFour)
                    .modifier(OtpModifer(pin: $pinFour))
                    .onChange(of: pinFour) { newVal in
                        if newVal.count == 0 {
                            pinFocusState = .pinThree
                        } else if newVal.count == 1 {
                            pinFocusState = .pinFive
                        }
                    }
                    .focused($pinFocusState, equals: .pinFour)
                
                TextField("", text: $pinFive)
                    .modifier(OtpModifer(pin: $pinFive))
                    .onChange(of: pinFive) { newVal in
                        if newVal.count == 0 {
                            pinFocusState = .pinFour
                        } else if newVal.count == 1 {
                            pinFocusState = .pinSix
                        }
                    }
                    .focused($pinFocusState, equals: .pinFive)
                    
                TextField("", text: $pinSix)
                    .modifier(OtpModifer(pin: $pinSix))
                    .onChange(of: pinSix) { newVal in
                        if newVal.count == 0 {
                            pinFocusState = .pinFive
                        } else if newVal.count == 1 {
                            verifyOTP()
                        }
                    }
                    .focused($pinFocusState, equals: .pinSix)
            }
            .foregroundColor(.black)
            .padding(.vertical)
            .padding(.horizontal)
            
            Button(action: verifyOTP) {
                Text("Verify Code")
                    .font(.sfRounded(size: .base, weight: .semibold))
                    .foregroundColor(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(AppColors.primaryPurple)
                    .cornerRadius(26)
            }.padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .background(.black)
        .onAppear {
            privy.email.setOtpFlowStateChangeCallback { state in
                otpFlowState = state
            }
            handleEmailLogin() // Automatically send OTP on appearance
        }
        .dismissKeyboardOnTap()
    }
}
