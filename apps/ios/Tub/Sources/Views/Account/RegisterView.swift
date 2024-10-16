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
                .foregroundColor(.white)
                .padding(5)
            
            ZStack(alignment: .leading) {
                if username.isEmpty {
                    Text("Username")
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.leading, 30.0)
                }
                TextField("", text: $username)
                    .padding()
                    .font(.sfRounded(size: .lg))
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)  // Custom border
                    )
                    .padding(.horizontal)
            }
            
            Button(action: {
                Network.shared.registerNewUser(username: username, airdropAmount: "100000000000", completion: handleRegistration)
            }) {
                Text("Register")
                    .font(.sfRounded(size: .lg, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(.blue)
                    .cornerRadius(26)
            }.padding([.top, .leading, .trailing])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    @State @Previewable var isRegistered = false
    return RegisterView(isRegistered: $isRegistered)
}
