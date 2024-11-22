import AuthenticationServices
import PrivySDK
import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss  // Add this line
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
            }
            else {
                showEmailError = true
                showEmailModal = false
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            HStack {
                if isRedirected {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(Color.white)
                            .padding(.horizontal)
                    }
                }
                else {
                    Spacer().frame(height: 10)
                }

                Spacer()
            }
            

            VStack(alignment: .leading, spacing: 12) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 10)

                Text("Welcome to tub")
                    .font(.sfRounded(size: .xl2, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Enter your email", text: $email)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(30)
                        .keyboardType(.emailAddress)
                        .foregroundStyle(Color.black)
                        .onChange(of: email) { _, newValue in
                            isEmailValid = validateEmail(newValue)
                            showEmailError = false
                        }

                    PrimaryButton(
                        text: "Continue",
                        textColor: Color.white,
                        backgroundColor: Color("purple"),
                        strokeColor: Color("purple"),
                        maxWidth: .infinity,
                        action: {
                            if isEmailValid {
                                sendEmailOtp(email: email)
                            }
                        }
                    )
                    .disabled(!isEmailValid || sendingEmailOtp)
                    .opacity(!isEmailValid || sendingEmailOtp ? 0.5 : 1.0)

                    // if email invalid
                    if showEmailError {
                        Text("Please enter a valid email address.")
                            .font(.caption)
                            .foregroundStyle(Color.red)
                            .padding(.top, -4)
                            .padding(.horizontal, 20)
                    }
                    else {
                        // Invisible placeholder to maintain spacing
                        Text("")
                            .font(.caption)
                            .padding(.top, -4)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal)
                // or divider line
                HStack(alignment: .center, spacing: 12) {
                    Divider()
                        .frame(width: 153, height: 1)
                        .overlay(
                            Rectangle()
                                .stroke(Color("grayLight"), lineWidth: 1)
                        )

                    Text("or")
                        .font(.sfRounded(size: .base, weight: .semibold))
                        .foregroundStyle(Color.white)

                    Divider()
                        .frame(width: 153, height: 1)
                        .overlay(
                            Rectangle()
                                .stroke(Color("grayLight"), lineWidth: 1)
                        )
                }.frame(maxWidth: .infinity)

                // Apple Login
                SignInWithApple()
                    .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .center)
                    .cornerRadius(30)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .inset(by: 0.5)
                            .stroke(Color.white, lineWidth: 1)
                            .padding(.horizontal, 10)
                    )
                    .onTapGesture {
                        // Ideally this is called in a view model, but showcasinlug logic here for brevity
                        Task {
                            do {
                                let _ = try await privy.oAuth.login(with: OAuthProvider.apple)
                            }
                            catch {
                                notificationHandler.show(
                                    error.localizedDescription,
                                    type: .error
                                )
                            }
                        }
                    }

                // Google Login
                OutlineButtonWithIcon(
                    text: "Sign in with Google",
                    textColor: Color.white,
                    strokeColor: Color.white,
                    backgroundColor: Color.black,
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
                .padding(.horizontal, 10)
                
                // Phone button
                IconTextButton(
                    icon: "phone.fill",
                    text: "Continue with Phone",
                    textColor: Color.white,
                    action: { showPhoneModal = true }
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10.0)

                IconTextButton(
                    icon: "ladybug.fill",
                    text: "Dev Login",
                    textColor: Color("grayLight"),
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
                .padding(.vertical, 5)

            }.sheet(isPresented: $showPhoneModal) {
                SignInWithPhoneView()
                    .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showEmailModal) {
                SignInWithEmailView(email: $email)
                    .presentationDetents([.height(300)])
            }
            .padding(.top, 80)
        }
        .ignoresSafeArea(.keyboard)
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
        .padding(.vertical)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.darkBlueGradient)
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

