import SwiftUI
import PrivySDK
import AuthenticationServices

struct RegisterView: View {
    @AppStorage("userId") private var userId = ""
    @State private var username = ""
    @State private var email = ""
    @Binding var isRegistered: Bool
    @State var myAuthState : AuthState = AuthState.notReady
    @State private var showPhoneModal = false
    @State private var showEmailModal = false
    @State private var isEmailValid = false
    @State private var showEmailError = false
    
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
            VStack(spacing: 12) {
                Spacer()
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
                        Text("We only need your email to log you in.")
                            .font(.sfRounded(size: .base, weight: .medium))
                            .foregroundColor(AppColors.lightGray)
                            .padding(.horizontal,10)
                        
                        TextField("Enter your email", text: $email)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                            .background(AppColors.white)
                            .cornerRadius(30)
                            .keyboardType(.emailAddress)
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
                        }
                    }
                    
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
//                    .background(AppColors.black)
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .inset(by: 0.5)
                            .stroke(AppColors.white, lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .padding(.top,4)
                
                Spacer()
                
                // or divider line
                HStack(alignment: .center, spacing: 11) {
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
                // Phone button
                Button(action: { showPhoneModal = true }) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .frame(width: 24, height: 24)
                        
                        Text("Continue with Phone")
                            .font(.sfRounded(size: .lg, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(AppColors.white)
                
                // Google Login
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
                        .foregroundColor(AppColors.lightGray)
                        .frame(maxWidth: .infinity, maxHeight: 50)
                }
                
            }.sheet(isPresented: $showPhoneModal) {
                SignInWithPhoneView()
                    .presentationDetents([.height(400)])
            }
            .sheet(isPresented: $showEmailModal) {
                SignInWithEmailView(email: $email)
                    .presentationDetents([.height(400)])
            }
            .onAppear {
                privy.setAuthStateChangeCallback { state in
                    self.myAuthState = state
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.darkGreenGradient)
        }
    }
}

#Preview {
    @State @Previewable var isRegistered = false
    return RegisterView(isRegistered: $isRegistered)
}
