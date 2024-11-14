//
//  AccountView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var errorHandler: ErrorHandler
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @State private var isNavigatingToRegister = false
    @State private var isAirdropping = false
    @State private var airdropResult: String?
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    @State private var showOnrampView = false
       
    func performAirdrop() {
        isAirdropping = true
        airdropResult = nil
        
        Network.shared.airdropNativeToUser(amount: 1 * Int(1e9)) { result in
            DispatchQueue.main.async {
                isAirdropping = false
                switch result {
                case .success:
                    airdropResult = "Airdrop successful!"
                case .failure(let error):
                    errorHandler.show(error)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack() {
                Text(serverBaseUrl).foregroundStyle(.white)
                if userModel.userId.isEmpty {
                    Text("Please register to view your account details.")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                        .padding()
                    NavigationLink(destination: RegisterView()) {
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
                        Text("User id: \(userModel.userId)")
                            .font(.sfRounded(size: .lg, weight: .medium))
                        Text("Wallet address: \(userModel.walletAddress)")
                            .font(.sfRounded(size: .lg, weight: .medium))
                        
                        Text("Balance: \(priceModel.formatPrice(lamports: userModel.balanceLamps, minDecimals: 2))")
                            .font(.sfRounded(size: .lg, weight: .medium))
                            .padding(.bottom)
                        if let result = airdropResult {
                            Text(result).foregroundColor(AppColors.green).padding()
                        }
                        if isAirdropping {
                            ProgressView()
                        }
                        else  {
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
                        
                        Button(action: { showOnrampView = true }) {
                            Text("Buy SOL")
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(AppColors.primaryPurple)
                                .cornerRadius(26)
                        }
                        .padding(.bottom, 5.0)
                        
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
            .sheet(isPresented: $showOnrampView) {
                CoinbaseOnrampView()
            }
        }
    }
}

