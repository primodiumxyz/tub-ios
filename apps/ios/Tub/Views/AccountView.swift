//
//  AccountView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct AccountView: View {
    @ObservedObject private var userModel: UserModel
    @State private var isNavigatingToRegister = false
    @State private var isAirdropping = false
    @State private var airdropResult: String?
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode

    init(userId: String) {
        userModel = UserModel(userId: userId)
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
                else if userModel.balance < 1 {
                    Button(action: performAirdrop) {
                        Text("Request Airdrop")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(isAirdropping)
                }
                
                Button(action: logout) {
                    Text("Logout")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
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
        .onChange(of: userId) { newValue in
            if newValue.isEmpty {
                presentationMode.wrappedValue.dismiss()
            }
        }
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
    
    private func logout() {
        userId = ""
        username = ""
    }
}

#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    AccountView(userId: userId)
}

