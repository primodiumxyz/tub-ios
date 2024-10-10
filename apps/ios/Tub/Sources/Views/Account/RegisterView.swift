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
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.black)
                .padding(.horizontal)
            
            Button(action: {
                Network.shared.registerNewUser(username: username, completion: handleRegistration)
            }) {
                Text("Register")
                    .font(.sfRounded(size: .lg, weight: .semibold))
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(red: 0.43, green: 0.97, blue: 0.98))
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    @State @Previewable var isRegistered = false
    return RegisterView(isRegistered: $isRegistered)
}
