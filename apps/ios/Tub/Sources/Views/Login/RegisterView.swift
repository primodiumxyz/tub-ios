import AuthenticationServices
import PrivySDK
import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var username = ""
    @State private var email = ""
    @State private var showPhoneModal = false
    @State private var showEmailModal = false
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @EnvironmentObject private var userModel: UserModel
    @State private var isEmailValid = false
    @State private var showEmailError = false
    @State private var sendingEmailOtp = false
    @State private var isRedirected: Bool

    init(isRedirected: Bool = false) {
        self.isRedirected = isRedirected
    }

    // Email validation function using regex
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func sendEmailOtp(email: String) {
        Task {
            if sendingEmailOtp { return }
            sendingEmailOtp = true
            let otpSent = await privy.email.sendCode(to: email)
            sendingEmailOtp = false
            if otpSent {
                showEmailError = false
                showEmailModal = true
            } else {
                showEmailError = true
                showEmailModal = false
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Cancel button
                HStack {
                    if isRedirected {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .padding(.horizontal)
                        }
                    } else {
                        Spacer().frame(height: geometry.size.height * 0.02)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: geometry.size.height * 0.018) {
                    // Logo
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, geometry.size.width * 0.04)
                    
                    // Welcome text
                    Text("Welcome to tub")
                        .font(.sfRounded(size: .xl2, weight: .semibold))
                        .padding(.horizontal, geometry.size.width * 0.04)
                    
                    // Email input section
                    VStack(alignment: .leading, spacing: geometry.size.height * 0.015) {
                        TextField("Enter your email", text: $email)
                            .padding(.horizontal, geometry.size.width * 0.05)
                            .padding(.vertical, geometry.size.height * 0.015)
                            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                            .background(Color(UIColor.systemBackground))
                            .foregroundStyle(.tubBuyPrimary)
                            .cornerRadius(30)
                            .keyboardType(.emailAddress)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(.tubBuyPrimary, lineWidth: 0.5)
                            )
                            .onChange(of: email) { _, newValue in
                                isEmailValid = validateEmail(newValue)
                                showEmailError = !isEmailValid && !newValue.isEmpty
                            }
                        
                        if showEmailError {
                            Text("Please enter a valid email address.")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.top, -4)
                                .padding(.horizontal, geometry.size.width * 0.05)
                        } else {
                            Text("")
                                .font(.caption)
                                .padding(.top, -4)
                                .padding(.horizontal, geometry.size.width * 0.05)
                        }
                        
                        Spacer().frame(height: geometry.size.height * 0.01)
                        
                        // Continue button
                        PrimaryButton(
                            text: "Continue",
                            textColor: .white,
                            backgroundColor: .tubSellPrimary,
                            strokeColor: .clear,
                            maxWidth: .infinity,
                            action: {
                                if isEmailValid {
                                    sendEmailOtp(email: email)
                                }
                            }
                        )
                        .disabled(!isEmailValid || sendingEmailOtp)
                        .opacity(!isEmailValid || sendingEmailOtp ? 0.8 : 1.0)
                    }
                    .padding(.horizontal, geometry.size.width * 0.04)
                    
                    // Divider
                    HStack(alignment: .center, spacing: geometry.size.width * 0.03) {
                        Divider()
                            .frame(width: geometry.size.width * 0.35, height: 1)
                            .overlay(
                                Rectangle()
                                    .stroke(.tubSellPrimary.opacity(0.5), lineWidth: 0.5)
                            )
                        
                        Text("or")
                            .font(.sfRounded(size: .base, weight: .semibold))
                            .foregroundStyle(.tubSellPrimary)
                        
                        Divider()
                            .frame(width: geometry.size.width * 0.35, height: 1)
                            .overlay(
                                Rectangle()
                                    .stroke(.tubSellPrimary.opacity(0.5), lineWidth: 0.5)
                            )
                    }
                    .padding(.horizontal, geometry.size.width * 0.1)
                    
                    // Social login buttons
                    VStack(spacing: geometry.size.height * 0.015) {
                        // Apple Login
                        SignInWithApple()
                            .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                            .cornerRadius(30)
                            .padding(.horizontal, geometry.size.width * 0.04)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .inset(by: 0.5)
                                    .stroke(.white, lineWidth: 1)
                                    .padding(.horizontal, geometry.size.width * 0.04)
                            )
                            .onTapGesture {
                                Task {
                                    do {
                                        let _ = try await privy.oAuth.login(with: OAuthProvider.apple)
                                    } catch {
                                        notificationHandler.show(error.localizedDescription, type: .error)
                                    }
                                }
                            }
                        
                        // Google Login
                        OutlineButtonWithIcon(
                            text: "Sign in with Google",
                            textColor: .white,
                            strokeColor: .white,
                            backgroundColor: .black,
                            leadingView: AnyView(GoogleLogoView()),
                            action: {
                                Task {
                                    do {
                                        let _ = try await privy.oAuth.login(with: OAuthProvider.google)
                                    } catch {
                                        notificationHandler.show(error.localizedDescription, type: .error)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, geometry.size.width * 0.04)
                        
                        // Phone button
                        IconTextButton(
                            icon: "phone.fill",
                            text: "Continue with Phone",
                            textColor: .tubBuyPrimary,
                            action: { showPhoneModal = true }
                        )
                        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
                        .padding(.top, geometry.size.height * 0.022)
                        
                        // Dev Login (if needed)
                        #if DEBUG
                        IconTextButton(
                            icon: "ladybug.fill",
                            text: "Dev Login",
                            textColor: .tubSellPrimary,
                            action: {
                                Task {
                                    do {
                                        let _ = await privy.email.sendCode(to: "test-0932@privy.io")
                                        let _ = try await privy.email.loginWithCode("145288", sentTo: "test-0932@privy.io")
                                    } catch {
                                        notificationHandler.show(error.localizedDescription, type: .error)
                                    }
                                }
                            }
                        )
                        .frame(maxWidth: .infinity)
                        #endif
                    }
                }
                .padding(.top, geometry.size.height * 0.08)
            }
        }
        .sheet(isPresented: $showPhoneModal) {
            SignInWithPhoneView()
                .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showEmailModal) {
            SignInWithEmailView(email: $email)
                .presentationDetents([.height(300)])
        }
        .ignoresSafeArea(.keyboard)
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: userModel.userId) { _, newUserId in
            if newUserId != nil {
                dismiss()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    @Previewable @StateObject var notificationHandler = NotificationHandler()
    @Previewable @StateObject var userModelxyz = UserModel.shared
    RegisterView()
        .environmentObject(notificationHandler)
        .environmentObject(userModelxyz)
}
