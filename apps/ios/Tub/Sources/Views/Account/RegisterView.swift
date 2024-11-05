import SwiftUI
import AuthenticationServices

struct RegisterView: View {
    @AppStorage("userId") private var userId = ""
    @State private var username = ""
    @Binding var isRegistered: Bool
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

            ZStack(alignment: .leading) {
                if username.isEmpty {
                    Text("Username")
                        .foregroundColor(AppColors.white.opacity(0.6))
                        .padding(.leading, 30.0)
                }
                TextField("", text: $username)
                    .padding(15.0)
                    .font(.sfRounded(size: .lg))
                    .foregroundColor(AppColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.lightGray.opacity(0.7), lineWidth: 1)
                    )
                    .padding(.horizontal)
            }
            
            Button(action: {
                Network.shared.registerNewUser(username: username, airdropAmount: String(Int(1.0 * 1e9))) { result in
                    handleRegistration(completion: result)
                }
            }) {
                Text("Sign In")
                    .font(.sfRounded(size: .base, weight: .semibold))
                    .foregroundColor(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(AppColors.primaryPurple)
                    .cornerRadius(26)
                }.padding([.top, .leading, .trailing])               
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.darkBlueGradient)
    }
}

#Preview {
    @State @Previewable var isRegistered = false
    return RegisterView(isRegistered: $isRegistered)
}
