//
//  SignInWithPhoneView.swift
//  Tub
//
//  Created by Henry on 10/31/24.
//
import SwiftUI
import PrivySDK

enum FocusPin {
    case pinOne, pinTwo, pinThree, pinFour, pinFive, pinSix
}

struct SignInWithPhoneView: View {
    @State private var phoneNumber = ""
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
            Text("Continue with Phone")
                .foregroundStyle(.white)
            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .keyboardType(.phonePad)
            
            if showOTPInput {
                Text("Enter verification code")
                    .font(.sfRounded(size: .base, weight: .medium))
                    .foregroundStyle(.white)

                HStack(spacing: 15) {
                    TextField("", text: $pinOne)
                        .modifier(OtpModifer(pin: $pinOne))
                        .onChange(of: pinOne) { newVal in
                            if newVal.count == 1 {
                                pinFocusState = .pinTwo
                            }
                        }
                        .focused($pinFocusState, equals: .pinOne)
                    
                    TextField("", text: $pinTwo)
                        .modifier(OtpModifer(pin: $pinTwo))
                        .onChange(of: pinTwo) { newVal in
                            if newVal.count == 1 {
                                pinFocusState = .pinThree
                            } else if newVal.count == 0 {
                                pinFocusState = .pinOne
                            }
                        }
                        .focused($pinFocusState, equals: .pinTwo)
                    
                    TextField("", text: $pinThree)
                        .modifier(OtpModifer(pin: $pinThree))
                        .onChange(of: pinThree) { newVal in
                            if newVal.count == 1 {
                                pinFocusState = .pinFour
                            } else if newVal.count == 0 {
                                pinFocusState = .pinTwo
                            }
                        }
                        .focused($pinFocusState, equals: .pinThree)
                    
                    TextField("", text: $pinFour)
                        .modifier(OtpModifer(pin: $pinFour))
                        .onChange(of: pinFour) { newVal in
                            if newVal.count == 1 {
                                pinFocusState = .pinFive
                            } else if newVal.count == 0 {
                                pinFocusState = .pinThree
                            }
                        }
                        .focused($pinFocusState, equals: .pinFour)
                    
                    TextField("", text: $pinFive)
                        .modifier(OtpModifer(pin: $pinFive))
                        .onChange(of: pinFive) { newVal in
                            if newVal.count == 1 {
                                pinFocusState = .pinSix
                            } else if newVal.count == 0 {
                                pinFocusState = .pinFour
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
                .padding(.vertical)
                .padding(.horizontal)
                
                Button(action: verifyOTP) {
                    Text("Verify Code")
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
        }
        .frame(maxHeight: .infinity)
        .background(.black)
        .onAppear {
            privy.sms.setOtpFlowStateChangeCallback { state in
                otpFlowState = state
            }
        }
    }
}
