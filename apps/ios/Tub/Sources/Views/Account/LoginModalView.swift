//
//  LoginModalView.swift
//  Tub
//
//  Created by yixintan on 11/14/24.
//

import SwiftUI
import PrivySDK
import AuthenticationServices

struct LoginModalView: View {
    @State private var email = ""
    @State private var showPhoneModal = false
    @State private var showEmailModal = false
    @State private var isEmailValid = false
    @State private var showEmailError = false
    @State private var agreedToTerms: Bool = false
    @State private var showMoreOptions = false
    @State private var showTermsError = false
    @EnvironmentObject private var errorHandler: ErrorHandler
    
    // Email validation function using regex
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to Tub!")
                .font(.sfRounded(size: .xl2, weight: .bold))
                .foregroundColor(AppColors.white)
                .padding(.top, 30)
                .padding(.bottom, 10)
            
            // Email TextField
            VStack(alignment: .leading, spacing: 10) {
                TextField("Enter your email", text: $email)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .background(AppColors.white)
                    .cornerRadius(30)
                    .keyboardType(.emailAddress)
                    .foregroundColor(.black)
                    .onChange(of: email) { newValue in
                        isEmailValid = validateEmail(newValue)
                        showEmailError = false
                    }
                
                // Terms Checkbox
                HStack {
                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreedToTerms ? AppColors.primaryPink : AppColors.lightGray)
                        .onTapGesture {
                            agreedToTerms.toggle()
                        }

                    Text("I agree to the ")
                        .foregroundColor(AppColors.lightGray)
                        + Text("Terms of Service")
                        .foregroundColor(AppColors.primaryPink)
                        .underline()
                        + Text(" and ")
                        .foregroundColor(AppColors.lightGray)
                        + Text("Privacy Policy")
                        .foregroundColor(AppColors.primaryPink)
                        .underline()
                }
                .font(.sfRounded(size: .sm))
                .padding(.horizontal)
                
                // if email invalid
                if showEmailError {
                    Text("Please enter a valid email address.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, -4)
                        .padding(.horizontal, 20)
                } else {
                    Text("")
                        .font(.caption)
                        .padding(.top, -4)
                        .padding(.horizontal, 20)
                }
                
                if showTermsError {
                    Text("Please agree to the Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, -4)
                        .padding(.horizontal, 20)
                }else {
                    Text("")
                        .font(.caption)
                        .padding(.top, -4)
                        .padding(.horizontal, 20)
                }
            }
            .frame(height: 80)

                        
            VStack(spacing:16){
                Button(action: {
                    if !agreedToTerms {
                        showTermsError = true
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        return
                    }
                    showTermsError = false
                    if isEmailValid {
                        showEmailModal = true
                    } else {
                        showEmailError = true
                    }
                }) {
                    Text("Continue")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                }
                .background(agreedToTerms ? AppColors.primaryPink : AppColors.primaryPink.opacity(0.5))
                .cornerRadius(30)
                
                // or divider line
                HStack(alignment: .center, spacing: 12) {
                    Divider()
                        .frame(width: 153, height: 1)
                        .overlay(
                            Rectangle()
                                .stroke(AppColors.lightGray, lineWidth: 0.5)
                        )
                    
                    Text("or")
                        .font(.sfRounded(size: .base, weight: .semibold))
                        .foregroundColor(AppColors.white)
                    
                    Divider()
                        .frame(width: 153, height: 1)
                        .overlay(
                            Rectangle()
                                .stroke(AppColors.lightGray, lineWidth: 0.5)
                        )
                }
                
                // Apple Login
                SignInWithApple()
                    .frame(maxWidth: .infinity, maxHeight: 50, alignment: .center)
                    .cornerRadius(30)
                    .padding(.horizontal,10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .inset(by: 0.5)
                            .stroke(.white, lineWidth: 1)
                            .padding(.horizontal,10)
                    )
                    .onTapGesture {
                        // Ideally this is called in a view model, but showcasinlug logic here for brevity
                        Task {
                            do {
                                let authSession = try await privy.oAuth.login(with: OAuthProvider.apple)
                            } catch {
                                errorHandler.show(error)
                            }
                        }
                    }
                
                if !showMoreOptions {
                    Button(action: {
                        withAnimation {
                            showMoreOptions.toggle()
                        }
                    }) {
                        HStack {
                            Text("More")
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    }
                }
                
                if showMoreOptions {
                    VStack(spacing: 8) {
                        // Google Login
                        Button(action: {
                            Task {
                                do {
                                    let _ = try await privy.oAuth.login(with: OAuthProvider.google)
                                } catch {
                                    errorHandler.show(error)
                                }
                            }
                        }) {
                            HStack(alignment: .center, spacing: 8) {
                                GoogleLogoView()
                                    .frame(width: 20, height: 20)
                                Text("Sign in with Google").font(.sfRounded(size: .lg, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(10)
                            .padding(.vertical, 5.0)
                        }
                        .background(AppColors.black)
                        .foregroundStyle(AppColors.white)
                        .cornerRadius(30)
                        .padding(.horizontal,10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .inset(by: 0.5)
                                .stroke(.white, lineWidth: 1)
                                .padding(.horizontal,10)
                        )
                        
                        // Phone Login
                        Button(action: { showPhoneModal = true }) {
                            HStack(alignment: .center) {
                                Image(systemName: "phone.fill")
                                    .frame(width: 24, height: 24)
                                
                                Text("Continue with Phone")
                                    .font(.sfRounded(size: .lg, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6.0)
                        .foregroundStyle(AppColors.white)
                        
                        // Dev Login
                        Button(action: {
                            Task {
                                do {
                                    // Send OTP to test email
                                    let _ = await privy.email.sendCode(to: "test-0932@privy.io")
                                    // Login with predefined OTP
                                    let _ = try await privy.email.loginWithCode("145288", sentTo: "test-0932@privy.io")
                                } catch {
                                    errorHandler.show(error)
                                }
                            }
                        }) {
                            HStack() {
                                Image(systemName: "ladybug.fill")
                                    .frame(width: 24, height: 24)

                                Text("Dev Login")
                                    .font(.sfRounded(size: .base, weight: .semibold))
                            }
                            .foregroundColor(AppColors.lightGray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                    }
                    .offset(y:-6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding()
        .frame(maxWidth: 400)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showPhoneModal) {
            SignInWithPhoneView()
                .presentationDetents([.height(500)])
        }
        .sheet(isPresented: $showEmailModal) {
            SignInWithEmailView(email: $email)
                .presentationDetents([.height(400)])
        }
        .dismissKeyboardOnTap()
        .background(AppColors.pinkGradient)
        .background(AppColors.black)
        .cornerRadius(30)
        .shadow(radius: 10)
    }
}

// Preview Provider
struct LoginModalView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)
            LoginModalView()
        }
    }
} 
