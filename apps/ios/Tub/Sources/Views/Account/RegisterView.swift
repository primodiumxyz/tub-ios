import SwiftUI

struct RegisterView: View {
    @AppStorage("userId") private var userId = ""
    @State private var username = ""
    @Binding var isRegistered: Bool
    
    func handleRegistration(completion: Result<UserResponse, Error>) {
        switch completion {
        case .success(let user):
            userId = user.uuid
            isRegistered = true
        case .failure(let error):
            print("Registration failed: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Tub")
                .font(.sfRounded(size: .xl3, weight: .bold))
                .foregroundColor(AppColors.white)
                .padding(5)
            
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
                Network.shared.registerNewUser(username: username, airdropAmount: "100000000000", completion: handleRegistration)
            }) {
                Text("Register")
                    .font(.sfRounded(size: .lg, weight: .semibold))
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
