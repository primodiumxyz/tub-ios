import SwiftUI
import PrivySDK
import AuthenticationServices

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
    @State private var isRedirected : Bool
    
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
        ScrollView(showsIndicators: false) {
            HStack {
                
				if isRedirected {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark.circle")
							.foregroundColor(.white)
							.padding(.horizontal)
					}
				} else {
                    Spacer().frame(height:10)
                }
                
                Spacer()
            }
            VStack(alignment: .leading, spacing: 12){
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal,10)
                
                Text("Welcome to tub")
                    .font(.sfRounded(size: .xl2, weight: .semibold))
                    .foregroundColor(AppColors.white)
                    .padding(.horizontal,10)
                
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Enter your email", text: $email)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .background(AppColors.white)
                        .cornerRadius(30)
                        .keyboardType(.emailAddress)
                        .foregroundColor(.black)
                        .onChange(of: email) { _, newValue in
                            isEmailValid = validateEmail(newValue)
                            showEmailError = false
                        }
                    
                    
                    
                    
                    Button(action: {
                        if isEmailValid {
                            sendEmailOtp(email: email)
                        } else {
                        }
                    }) {
                        Text("Continue")
                            .font(.sfRounded(size: .lg, weight: .semibold))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                    }
                    .disabled(!isEmailValid || sendingEmailOtp)
                    .opacity(!isEmailValid || sendingEmailOtp ? 0.5 : 1.0)
                    .background(AppColors.primaryPurple)
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .inset(by: 0.5)
                            .stroke(AppColors.primaryPurple, lineWidth: 1)
                    )
                    .opacity(!isEmailValid || sendingEmailOtp ? 0.5 : 1.0)
                    
                    // if email invalid
                    if showEmailError {
                        Text("Please enter a valid email address.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, -4)
                            .padding(.horizontal, 20)
                    } else {
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
                                .stroke(AppColors.lightGray, lineWidth: 1)
                        )
                    
                    Text("or")
                        .font(.sfRounded(size: .base, weight: .semibold))
                        .foregroundColor(AppColors.white)
                    
                    Divider()
                        .frame(width: 153, height: 1)
                        .overlay(
                            Rectangle()
                                .stroke(AppColors.lightGray, lineWidth: 1)
                        )
                }.frame(maxWidth: .infinity )
                
                // Apple Login
                SignInWithApple()
					.frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .center)
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
                                let _ = try await privy.oAuth.login(with: OAuthProvider.apple)
                            } catch {
                                notificationHandler.show(error.localizedDescription,
                                    type: .error
                                )
                            }
                        }
                    }
                
                // Google Login
                Button(action: {
                    Task {
                        do {
                            let _ = try await privy.oAuth.login(with: OAuthProvider.google)
                        } catch {
                            notificationHandler.show(
                                error.localizedDescription,
                                type: .error
                            )
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
                
                // Phone button
                Button(action: { showPhoneModal = true }) {
                    HStack(alignment: .center) {
                        Image(systemName: "phone.fill")
                            .frame(width: 24, height: 24)
                        
                        Text("Continue with Phone")
                            .font(.sfRounded(size: .lg, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10.0)
                .foregroundStyle(AppColors.white)
                Button(action: {
                    Task {
                        do {
                            // Send OTP to test email
                            let _ = await privy.email.sendCode(to: "test-0932@privy.io")
                            // Login with predefined OTP
                            let _ = try await privy.email.loginWithCode("145288", sentTo: "test-0932@privy.io")
                        } catch {
                            notificationHandler.show(
                                error.localizedDescription,
                                type: .error
                            )
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
	RegisterView()
}
