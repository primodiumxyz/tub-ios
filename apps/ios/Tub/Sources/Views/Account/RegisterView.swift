import SwiftUI
import PrivySDK
import AuthenticationServices

struct RegisterView: View {
    @AppStorage("userId") private var userId = ""
    @State private var username = ""
    @Binding var isRegistered: Bool
    @State var myAuthState : AuthState = AuthState.notReady
    
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
                        // Ideally this is called in a view model, but showcasing logic here for brevity
                        Task {
                            do {
                                let authSession = try await privy.oAuth.login(with: OAuthProvider.apple)
                                print(authSession.user)
                            } catch {
                                debugPrint("Error: \(error)")
                            }
                        }
                    }
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
            }.onAppear {
                privy.setAuthStateChangeCallback { state in
                    self.myAuthState = state
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
