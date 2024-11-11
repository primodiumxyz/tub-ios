import SwiftUI
import PrivySDK
import AuthenticationServices

struct RegisterView: View {
    @AppStorage("userId") private var userId = ""
    @State private var username = ""
    @State private var email = ""
    @State private var showPhoneModal = false
    @State private var showEmailModal = false
    @EnvironmentObject private var errorHandler: ErrorHandler
    @State private var isEmailValid = false
    @State private var showEmailError = false
    
    func createEmbeddedWallet() {
        Task {
            do {
                // Ensure we're authenticated first
                guard case .authenticated = privy.authState else { return }
                
                // Get the current embedded wallet state
                let walletState = privy.embeddedWallet.embeddedWalletState
                
                // Check if we need to create a wallet
                switch walletState {
                case .notCreated:
                    // Create a new embedded wallet
                    print("Creating new embedded wallet")
                    let _ = try await privy.embeddedWallet.createWallet(allowAdditional: false)
                case .connected(let wallets):
                    print("Wallet already exists: \(wallets)")
                default:
                    print("Wallet state: \(walletState.toString)")
                }
            } catch {
                errorHandler.show(error)
            }
        }
    }
    // Email validation function using regex
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    var body: some View {
        
            VStack(spacing: 10) {
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12){
                            Spacer()
                                .frame(height: geometry.size.height * 0.25)
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
                                    .onChange(of: email) { newValue in
                                        isEmailValid = validateEmail(newValue)
                                        showEmailError = false
                                    }
                                
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
                            .frame(height: 80) // Adjust this value to accommodate both states
                            
                            Spacer()
                                .frame(height: 30)
                            
                            Button(action: {
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
                            .background(AppColors.primaryPurple)
                            .cornerRadius(30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .inset(by: 0.5)
                                    .stroke(AppColors.primaryPurple, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                // .frame(maxHeight: .infinity)
                
                VStack(spacing: 15) {
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
                                    print(authSession.user)
                                } catch {
                                    errorHandler.show(error)
                                }
                            }
                        }
                    
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
                    
            // Add dev login button in debug builds only
                #if DEBUG
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
                #endif
                    
                }.sheet(isPresented: $showPhoneModal) {
                    SignInWithPhoneView()
                        .presentationDetents([.height(500)])
                }
                .sheet(isPresented: $showEmailModal) {
                    SignInWithEmailView(email: $email)
                        .presentationDetents([.height(400)])
                }
            }
            .ignoresSafeArea(.keyboard)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.darkBlueGradient)
            .dismissKeyboardOnTap()
        }
    }

#Preview {
    return RegisterView()
}
