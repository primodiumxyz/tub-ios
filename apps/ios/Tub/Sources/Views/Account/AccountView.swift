//
//  AccountView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var userModel: UserModel
    @State private var isNavigatingToRegister = false
    @State private var isAirdropping = false
    @State private var airdropResult: String?
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            if userModel.username.isEmpty {
                Text("Please log in (go to register) to view your account details")
                    .font(.sfRounded(size: .lg, weight: .medium))
                    .foregroundColor(.yellow)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Username: \(userModel.username)")
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
                    
                    Button(action: userModel.logout) {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationTitle("Account")
        .onChange(of: userModel.userId) { newValue in
            if newValue.isEmpty {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func performAirdrop() {
        isAirdropping = true
        airdropResult = nil
        
        Network.shared.airdropNativeToUser(accountId: userModel.userId, amount: 100) { result in
            DispatchQueue.main.async {
                isAirdropping = false
                switch result {
                case .success(_):
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
    AccountView()
        .environmentObject(UserModel(userId: userId))
}

