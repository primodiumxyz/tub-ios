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
    @EnvironmentObject private var errorHandler: ErrorHandler
    @State private var phoneNumber = ""
    @State private var showOTPInput = false
    @State private var signingIn : Bool = false
    
    @State private var showPhoneError = false
    @State private var selectedCountryCode = countryCodes[0].code
    
    private func format(with mask: String, phone: String) -> String {
        let numbers = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        var result = ""
        var index = numbers.startIndex
        
        for ch in mask where index < numbers.endIndex {
            if ch == "X" {
                result.append(numbers[index])
                index = numbers.index(after: index)
            } else {
                result.append(ch)
            }
        }
        return result
    }
    
    private var formattedPhoneBinding: Binding<String> {
        Binding(
            get: { phoneNumber },
            set: { newValue in
                let formatted = format(with: "(XXX) XXX-XXXX", phone: newValue)
                phoneNumber = formatted
            }
        )
    }
    
    private func handlePhoneLogin() {
        if signingIn { return }
        if phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber) {
            showPhoneError = true
            return
        }
        Task {
            signingIn = true
            let otpSent = await privy.sms.sendCode(to: phoneNumber)
            if otpSent {
                showOTPInput = true
            }else {
                let error = NSError(domain: "PrivyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to send OTP"])
                errorHandler.show(error)
                debugPrint("Error: Failed to send OTP.")
                
                showOTPInput = false
            }
            signingIn = false
        }
    }
    
    private func isValidPhoneNumber(_ number: String) -> Bool {
        let numbersOnly = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let phoneRegex = "^[0-9]{10,15}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: numbersOnly)
    }
    
    private func verifyOTP(otpCode: String) {
        Task {
            do {
                if signingIn { return }
                signingIn = true
                let _ = try await privy.sms.loginWithCode(otpCode, sentTo: phoneNumber)
                signingIn = false
            } catch {
                signingIn = false
                errorHandler.show(error)
                print(error)
            }
        }
    }
    
    
    var body: some View {
        VStack(spacing: 12) {
            if showOTPInput {
                VStack() {
                    Text("Enter verification code")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundColor(AppColors.white)
                        .padding(.top,16)
                        .padding(.horizontal,20)
                }
                OTPInputView(onComplete: verifyOTP)
                
            } else {
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
                    
                    TextField("Enter your Phone Number", text: formattedPhoneBinding)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(AppColors.white)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
                        .cornerRadius(30)
                        .onChange(of: phoneNumber) {
                            showPhoneError = false
                        }
                }
                .padding(.horizontal)
                Button(action: handlePhoneLogin) {
                    Text("Continue")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(26)
                }
                .disabled(signingIn)
                .padding(.horizontal)
                .padding(.top, 5)
                Text(showPhoneError ? "Please enter a valid phone number." : "")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, -4)
                    .padding(.horizontal,20)
                
            }
        }
        .frame(maxHeight: .infinity)
        .background(.black)
        
        .dismissKeyboardOnTap()
    }
}
