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
    @State private var showPhoneError = false
    @State private var selectedCountryCode = countryCodes[0].code
    
    private var otpCode: String {
        pinOne + pinTwo + pinThree + pinFour + pinFive + pinSix
    }
    
    private func handlePhoneLogin() {
        if phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber) {
            showPhoneError = true
            return
        }
        Task {
            let otpSent = await privy.sms.sendCode(to: phoneNumber)
            if otpSent {
                showOTPInput = true
            }else {
                debugPrint("Error: Failed to send OTP.")
                showOTPInput = false
            }
        }
    }
    
    private func isValidPhoneNumber(_ number: String) -> Bool {
        let phoneRegex = "^[0-9]{10,15}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: number)
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
        VStack(alignment:.leading, spacing: 12) {
            Text("Continue with Phone Number")
                .font(.sfRounded(size: .lg, weight: .medium))
                .foregroundColor(AppColors.white)
                .padding(.horizontal,20)
            
            HStack {
                Picker("Country Code", selection: $selectedCountryCode) {
                    ForEach(countryCodes, id: \.code) { country in
                        Text("\(country.name) \(country.code)").tag(country.code)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 100, height: 50)
                .background(AppColors.white)
                .cornerRadius(30)
                
                TextField("Enter your Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(AppColors.white)
                    .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
                    .cornerRadius(30)
                    .onChange(of: phoneNumber) { newValue in
                        showPhoneError = false
                    }
            }
            .padding(.horizontal)
            
            
            if showPhoneError {
                Text("Please enter a valid phone number.")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, -4)
                    .padding(.horizontal,20)

            }
            
            if showOTPInput {
                VStack(alignment:.leading) {
                    Text("Enter verification code")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundColor(AppColors.white)
                        .padding(.top,16)
                        .padding(.horizontal,20)
                }
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
                .padding(.vertical, 6)
                .padding(.horizontal, 20)
                
                Button(action: verifyOTP) {
                    Text("Verify Code")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(26)
                }.padding(.horizontal)
            } else {
                Button(action: handlePhoneLogin) {
                    Text("Continue")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(26)
                }
                .padding(.horizontal)
                .padding(.top, 5)
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
