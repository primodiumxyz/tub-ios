import SwiftUI
import PrivySDK
import AuthenticationServices

struct RegisterView: View {
    @State private var showPhoneModal = false
    @State private var showEmailModal = false
    

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
                    print("Error creating wallet: \(error.localizedDescription)")
                }
            }
    }
    
    var body: some View {
      
            VStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 16)
                
                Button(action: {
                    Task {
                        do {
                            let _ = try await privy.oAuth.login(with: OAuthProvider.google)
                        } catch {
                            debugPrint("Error: \(error)")
                            // Handle errors
                        }
                    }
                }) {
                    GoogleLogoView()
                        .frame(width: 24, height: 24)
                    
                    Text("Sign In With Google").font(.sfRounded(size: .xl, weight: .semibold))
                }.frame(width: 260).padding().background(.white).cornerRadius(26).foregroundStyle(.black)
                
                SignInWithApple()
                    .onTapGesture {
                        // Ideally this is called in a view model, but showcasinlug logic here for brevity
                        Task {
                            do {
                                let authSession = try await privy.oAuth.login(with: OAuthProvider.apple)
                                print(authSession.user)
                            } catch {
                                debugPrint("Error: \(error)")
                            }
                        }
                    }
                
                // Email button
                Button(action: { showEmailModal = true }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .frame(width: 24, height: 24)
                        
                        Text("Continue with Email")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                    }
                }
                .frame(width: 260)
                .padding()
                .background(.white)
                .cornerRadius(26)
                .foregroundStyle(.black)
                
                // Phone button
                Button(action: { showPhoneModal = true }) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .frame(width: 24, height: 24)
                        
                        Text("Continue with Phone")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                    }
                }
                .frame(width: 260)
                .padding()
                .background(.white)
                .cornerRadius(26)
                .foregroundStyle(.black)

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
                            debugPrint("Dev login error: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "ladybug.fill")
                            .frame(width: 24, height: 24)
                        
                        Text("Dev Login")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                    }
                }
                .frame(width: 260)
                .padding()
                .background(.red.opacity(0.8))
                .cornerRadius(26)
                .foregroundStyle(.white)
                #endif
            }.sheet(isPresented: $showPhoneModal) {
                SignInWithPhoneView()
                    .presentationDetents([.height(400)])
            }
            .sheet(isPresented: $showEmailModal) {
                SignInWithEmailView()
                    .presentationDetents([.height(400)])
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.darkBlueGradient)
    }
}

#Preview {
    RegisterView()
}
