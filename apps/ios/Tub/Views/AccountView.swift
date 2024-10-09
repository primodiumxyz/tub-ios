//
//  AccountView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct AccountView: View {
    @AppStorage("username") private var username: String = ""
    private var userId: String
    private var handleLogout: (() -> Void)?
    
    @ObservedObject private var userModel: UserModel
    @State private var isNavigatingToRegister = false
    @State private var isAirdropping = false
    @State private var airdropResult: String?
    @State private var errorMessage: String?

    init(userId: String, handleLogout: (() -> Void)? = nil) {
        self.userId = userId
        userModel = UserModel(userId: userId)
        self.handleLogout = handleLogout
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Username: \(username)")
                    .font(.sfRounded(size: .xl, weight: .medium))
                Text("Balance: \(userModel.balance, specifier: "%.2f") SOL")
                    .font(.sfRounded(size: .xl, weight: .medium))
                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }
                if let result = airdropResult {
                    Text(result).foregroundColor(.green).padding()
                }
                if isAirdropping {
                    ProgressView()
                }
                else {
                    Button(action: performAirdrop) {
                        Text("Request Airdrop")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(isAirdropping)
                }
                
                if let logout = handleLogout {
                    Button(action: logout) {
                        Text("Logout")
                            .font(.sfRounded(size: .lg, weight: .semibold))
                            .foregroundColor(.black)
                            .padding()
                            .background(Color(red: 0.43, green: 0.97, blue: 0.98))
                            .cornerRadius(10)
                    }
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            
           
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationTitle("Account")
        .background(
            NavigationLink(destination: RegisterView(), isActive: $isNavigatingToRegister) {
                EmptyView()
            }
        )
    }
    
     private func performAirdrop() {
        isAirdropping = true
        airdropResult = nil
        
        Network.shared.airdropNativeToUser(accountId: userId, amount: 100) { result in
            DispatchQueue.main.async {
                isAirdropping = false
                switch result {
                case .success(let transaction):
                    airdropResult = "Airdrop successful!"
                    errorMessage = nil
                case .failure(let error):
                    errorMessage = "Airdrop failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    AccountView(userId: userId)
}

