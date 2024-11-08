import SwiftUI
import PrivySDK
import AuthenticationServices

struct RegisterView: View {
    @AppStorage("userId") private var userId = ""
    @State private var username = ""
    @State private var email = ""
    @State var myAuthState : AuthState = AuthState.notReady
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
        if myAuthState.toString == "authenticated" {
            Text(myAuthState.toString)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 24)
            Button(action: {
                privy.logout()
            }) {
                Text("logout")
            }
            
        } else {
            VStack(spacing: 10) {
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .center, spacing: 12) {
                            Spacer()
                                .frame(height: geometry.size.height * 0.25)
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .frame(maxWidth: .infinity)
                            
                            Text("Welcome to tub")
                                .font(.sfRounded(size: .xl2, weight: .semibold))
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                            
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
                                Text("Enter")
                                    .font(.sfRounded(size: .base, weight: .semibold))
                                    .foregroundColor(AppColors.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.darkBlue)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
            .ignoresSafeArea(.keyboard)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.darkBlueGradient)
        }
            .onAppear {
                privy.setAuthStateChangeCallback { state in
                    self.myAuthState = state
                }
            }
        }
    }
}

#Preview {
    return RegisterView()
}
