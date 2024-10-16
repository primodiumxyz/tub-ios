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
        NavigationStack {
            VStack() {
                if userModel.username.isEmpty {
                    Text("Please log in to view your account details.")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                    NavigationLink(isActive: $isNavigatingToRegister) {
                        RegisterView(isRegistered: $isNavigatingToRegister)
                        } label: {
                            Text("Register Now")
                                .font(.sfRounded(size: .lg, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(.purple)
                                .cornerRadius(26)
                        }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account Information")
                            .font(.sfRounded(size: .xl2, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical)
                        Text("Username: \(userModel.username)")
                            .font(.sfRounded(size: .xl, weight: .medium))
                        Text("Balance: \(userModel.balance.total, specifier: "%.2f") SOL")
                            .font(.sfRounded(size: .xl, weight: .medium))
                            .padding(.bottom)
                        if let error = errorMessage {
                            Text(error).foregroundColor(.red)
                        }
                        if let result = airdropResult {
                            Text(result).foregroundColor(.green).padding()
                        }
                        if isAirdropping {
                            ProgressView()
                        }
                        else if userModel.balance.total < 1 {
                            Button(action: performAirdrop) {
                                Text("Request Airdrop")
                                    .font(.sfRounded(size: .lg, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(.blue)
                                    .cornerRadius(26)
                            }
                            .disabled(isAirdropping)
                        }
                        
                        Button(action: userModel.logout) {
                            Text("Logout")
                                .font(.sfRounded(size: .lg, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(.red)
                                .cornerRadius(26)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(20.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black)
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
    @State @Previewable var isRegistered = false
    AccountView()
        .environmentObject(UserModel(userId: userId))
}
