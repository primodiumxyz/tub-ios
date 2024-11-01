import SwiftUI
import PrivySDK
import AuthenticationServices

struct RegisterView: View {
    @AppStorage("userId") private var userId = ""
    @State private var username = ""
    @Binding var isRegistered: Bool
    @State var myAuthState : AuthState = AuthState.notReady
    @State private var showPhoneModal = false
    @State private var showEmailModal = false
    
    func handleRegistration(completion: Result<UserResponse, Error>) {
        switch completion {
        case .success(let user):
            userId = user.uuid
            UserDefaults.standard.set(user.uuid, forKey: "userId")
            isRegistered = true
            
                    case .failure(let error):
            print("Registration failed: \(error.localizedDescription)")
        }
    }

    func createEmbeddedWallet() {
        // Check for Solana wallet after successful registration
        print("Creating embedded wallet")
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
                        _ = try await privy.embeddedWallet.createWallet(allowAdditional: false)
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
        if myAuthState.toString == "authenticated" {
            Text(myAuthState.toString)
                .foregroundStyle(.black.opacity(0.5))
                .padding(.bottom, 24)
            
            Button(action: {
                privy.logout()
            }) {
                Text("logout")
            }
            
        } else {
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
                
                Button(action: {
                    Network.shared.registerNewUser(username: "test", airdropAmount: String(Int(1.0 * 1e9))) { result in
                        handleRegistration(completion: result)
                    }
                }) {
                    Text("Dev Login")
                        .font(.sfRounded(size: .base, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(26)
                }.padding([.top, .leading, .trailing])               
            }.sheet(isPresented: $showPhoneModal) {
                SignInWithPhoneView()
                    .presentationDetents([.height(400)])
            }
            .sheet(isPresented: $showEmailModal) {
                SignInWithEmailView()
                    .presentationDetents([.height(400)])
            }
            .onAppear {
                privy.setAuthStateChangeCallback { state in
                    self.myAuthState = state
                    createEmbeddedWallet()
                }
         
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.darkBlueGradient)
        }
    }
}

#Preview {
    @State @Previewable var isRegistered = false
    return RegisterView(isRegistered: $isRegistered)
}
