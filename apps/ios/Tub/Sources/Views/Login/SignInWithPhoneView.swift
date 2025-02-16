import PrivySDK
//
//  SignInWithPhoneView.swift
//  Tub
//
//  Created by Henry on 10/31/24.
//
import SwiftUI

enum FocusPin {
    case pinOne, pinTwo, pinThree, pinFour, pinFive, pinSix
}

struct SignInWithPhoneView: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @State private var phoneNumber = ""
    @State private var showOTPInput = false
    @State private var signingIn: Bool = false

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
            }
            else {
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
            }
            else {
                let error = TubError.networkFailure
                notificationHandler.show(
                    error.localizedDescription,
                    type: .error
                )
                debugPrint("Error: Failed to send OTP.")

                showOTPInput = false
            }
            signingIn = false
        }
    }

    private func isValidPhoneNumber(_ number: String) -> Bool {
        let numbersOnly = number.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        )
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
            }
            catch {
                signingIn = false
                notificationHandler.show(
                    error.localizedDescription,
                    type: .error
                )
                print(error)
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            if showOTPInput {
                VStack {
                    Text("Enter verification code")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                }
                OTPInputView(onComplete: verifyOTP)

            }
            else {
                HStack {
                    Picker("Country Code", selection: $selectedCountryCode) {
                        ForEach(countryCodes, id: \.code) { country in
                            Text("\(country.name) \(country.code)").tag(country.code)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100, height: 50)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(.tubBuyPrimary, lineWidth: 0.5)
                    )

                    TextField("Enter your Phone Number", text: formattedPhoneBinding)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .foregroundStyle(.tubBuyPrimary)
                        .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(.tubBuyPrimary, lineWidth: 0.5)
                        )
                        .onChange(of: phoneNumber) {
                            showPhoneError = false
                        }
                }

                PrimaryButton(text: "Continue", disabled: signingIn, action: handlePhoneLogin)
                Text(showPhoneError ? "Please enter a valid phone number." : "")
                    .foregroundStyle(.tubError)
                    .font(.caption)
                    .padding(.top, -4)
                    .padding(.horizontal, 20)

            }
        }
        .padding(.horizontal)
        .frame(maxHeight: .infinity)
        .background(Gradients.cardBgGradient)

        .dismissKeyboardOnTap()
    }
}
