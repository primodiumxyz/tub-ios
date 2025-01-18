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
            }
            else {
                showEmailError = true
                showEmailModal = false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIScreen.height(Layout.Spacing.xs)) {
            // Logo
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.width(Layout.Size.quarter), height: UIScreen.width(Layout.Size.quarter))
                .clipShape(RoundedRectangle(cornerRadius: Layout.Fixed.cornerRadius))
                .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
            
            // Welcome text
            Text("Welcome to tub")
                .font(.sfRounded(size: .xl2, weight: .semibold))
                .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
            
            // Email input section
            VStack(alignment: .leading, spacing: UIScreen.height(Layout.Spacing.xs)) {
                TextField("Enter your email", text: $email)
                    .padding(.horizontal, UIScreen.width(Layout.Spacing.md))
                    .padding(.vertical, UIScreen.height(Layout.Spacing.xs))
                    .frame(maxWidth: .infinity, minHeight: Layout.Fixed.buttonHeight, alignment: .leading)
                    .background(Color(UIColor.systemBackground))
                    .foregroundStyle(.tubBuyPrimary)
                    .cornerRadius(Layout.Fixed.cornerRadius)
                    .keyboardType(.emailAddress)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.Fixed.cornerRadius)
                            .stroke(.tubBuyPrimary, lineWidth: Layout.Fixed.borderWidth)
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
                        .padding(.horizontal, UIScreen.width(Layout.Spacing.md))
                }
                else {
                    Text("")
                        .font(.caption)
                        .padding(.top, -4)
                        .padding(.horizontal, UIScreen.width(Layout.Spacing.md))
                }
                
                Spacer().frame(height: UIScreen.height(Layout.Spacing.tiny))
                
                // Continue button
                PrimaryButton(
                    text: "Continue",
                    textColor: .white,
                    backgroundColor: .tubBuyPrimary,
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
            .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
            
            // Divider
            VStack(alignment: .center) {
                HStack(alignment: .center, spacing: UIScreen.width(Layout.Spacing.sm)) {
                    Divider()
                        .frame(width: UIScreen.width(Layout.Size.third), height: 1)
                        .overlay(
                            Rectangle()
                                .stroke(.tubBuyPrimary.opacity(0.5), lineWidth: Layout.Fixed.borderWidth)
                        )
                    
                    Text("or")
                        .font(.sfRounded(size: .base, weight: .semibold))
                        .foregroundStyle(.tubBuyPrimary)
                    
                    Divider()
                        .frame(width: UIScreen.width(Layout.Size.third), height: 1)
                        .overlay(
                            Rectangle()
                                .stroke(.tubBuyPrimary.opacity(0.5), lineWidth: Layout.Fixed.borderWidth)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            
            // Social login buttons
            VStack(spacing: UIScreen.height(Layout.Spacing.tiny)) {
                // Apple Login
                SignInWithApple()
                    .frame(
                        maxWidth: .infinity,
                        minHeight: Layout.Fixed.buttonHeight,
                        maxHeight: Layout.Fixed.buttonHeight
                    )
                    .cornerRadius(Layout.Fixed.cornerRadius)
                    .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.Fixed.cornerRadius)
                            .inset(by: Layout.Fixed.borderWidth)
                            .stroke(.white, lineWidth: 1)
                            .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
                    )
                    .onTapGesture {
                        Task {
                            do {
                                let _ = try await privy.oAuth.login(with: OAuthProvider.apple)
                            }
                            catch {
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
                            }
                            catch {
                                notificationHandler.show(error.localizedDescription, type: .error)
                            }
                        }
                    }
                )
                .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
                
                // Phone button
                IconTextButton(
                    icon: "Phone",
                    isSystemIcon: false,
                    text: "Continue with Phone",
                    textColor: .tubBuyPrimary,
                    iconSize: CGSize(width: 36, height: 36),
                    spacing: Layout.Spacing.xs,
                    action: { showPhoneModal = true }
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: Layout.Fixed.smallButtonHeight,
                    maxHeight: Layout.Fixed.smallButtonHeight
                )
                .padding(.top, UIScreen.height(Layout.Spacing.sm))
                
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
                                let _ = try await privy.email.loginWithCode(
                                    "145288",
                                    sentTo: "test-0932@privy.io"
                                )
                            }
                            catch {
                                notificationHandler.show(error.localizedDescription, type: .error)
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)
#endif
            }
        }
        .padding(.top, UIScreen.height(Layout.Spacing.lg))
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
    }
}

#Preview {
    @Previewable @StateObject var notificationHandler = NotificationHandler()
    @Previewable @StateObject var userModelxyz = UserModel.shared
    RegisterView()
        .environmentObject(notificationHandler)
        .environmentObject(userModelxyz)
}
