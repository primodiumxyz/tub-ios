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
                    Text("Please register to view your account details.")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                        .padding()
                    NavigationLink(destination: RegisterView(isRegistered: .constant(false))) {
                        Text("Register Now")
                            .font(.sfRounded(size: .base, weight: .semibold))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(AppColors.primaryPurple)
                            .cornerRadius(26)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account Information")
                            .font(.sfRounded(size: .xl2, weight: .medium))
                            .foregroundColor(AppColors.white)
                            .padding(.vertical)
                        Text("Username: \(userModel.username)")
                            .font(.sfRounded(size: .lg, weight: .medium))
                        Text("Balance: \(PriceFormatter.formatPrice(lamports: userModel.balanceLamps))")
                            .font(.sfRounded(size: .lg, weight: .medium))
                            .padding(.bottom)
                        if let error = errorMessage {
                            Text(error).foregroundColor(AppColors.red)
                        }
                        if let result = airdropResult {
                            Text(result).foregroundColor(AppColors.green).padding()
                        }
                        if isAirdropping {
                            ProgressView()
                        }
                        else if userModel.balanceLamps > 1 {
                            Button(action: performAirdrop) {
                                Text("Request Airdrop")
                                    .font(.sfRounded(size: .base, weight: .semibold))
                                    .foregroundColor(AppColors.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(AppColors.primaryPurple)
                                    .cornerRadius(26)
                            }
                            .disabled(isAirdropping)
                            .padding(.bottom, 5.0)
                        }
                        
                        Button(action: userModel.logout) {
                            Text("Logout")
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(AppColors.red)
                                .cornerRadius(26)
                        }
                    }
                    .foregroundColor(AppColors.white)
                    .padding(20.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cornerRadius(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.black)
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
        
        Network.shared.airdropNativeToUser(accountId: userModel.userId, amount: 100 * Int(1e9)) { result in
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
