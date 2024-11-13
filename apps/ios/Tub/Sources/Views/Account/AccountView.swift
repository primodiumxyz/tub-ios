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
            VStack(spacing: 24) {
                
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
                    Text(serverBaseUrl).foregroundStyle(.white)
                        .font(.caption)
                }
                else{
                    // User Name Placeholder
                    Text("Account")
                        .font(.sfRounded(size: .xl2, weight: .semibold))
                        .foregroundColor(AppColors.white)
                    
                    // Balance Section
                    VStack(spacing: 8) {
                        Text("Account Balance")
                            .font(.sfRounded(size: .lg, weight: .regular))
                            .foregroundColor(AppColors.lightGray.opacity(0.7))
                        
                        Text("\(priceModel.formatPrice(lamports: userModel.balanceLamps, maxDecimals: 2, minDecimals: 2))")
                            .font(.sfRounded(size: .xl5, weight: .bold))
                            .foregroundColor(.white)
                        
                        let adjustedPercentage = userModel.initialBalanceLamps != 0 ? 100 - (Double(userModel.balanceLamps) / Double(userModel.initialBalanceLamps)) * 100 : 100
                        
                        HStack {
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.green)
                            Text("\(abs(adjustedPercentage), specifier: "%.1f")% All Time")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top,16)
                    .padding(.bottom,12)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Spacer()
                        Button(action: performAirdrop) {
                            HStack {
                                if isAirdropping {
                                    ProgressView()
                                }
                                Text("Request Airdrop")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .foregroundColor(AppColors.primaryPink)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .inset(by: 0.5)
                                            .stroke(AppColors.primaryPink, lineWidth: 1)
                                    )
                            }
                        }.disabled(isAirdropping)
                        
                        Button(action: { showOnrampView = true }) {
                            Text("Add Funds")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .foregroundColor(AppColors.aquaGreen)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .inset(by: 0.5)
                                        .stroke(AppColors.aquaGreen, lineWidth: 1)
                                )
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if let result = airdropResult {
                        Text(result).foregroundColor(AppColors.green).padding()
                            .font(.caption)
                            .padding(-24)
                    }
                    
                    // Available Cash
                    VStack(spacing:24) {
                        Divider()
                            .frame(width: 370, height: 1)
                            .overlay(
                                Rectangle()
                                    .stroke(AppColors.lightGray.opacity(0.5), lineWidth: 0.5)
                            )
                        HStack() {
                            Text("Available Cash")
                                .foregroundColor(AppColors.lightGray)
                                .font(.sfRounded(size: .lg, weight: .medium))
                            
                            Spacer()
                            
                            Text("$0.00")
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal,8)
                                .foregroundColor(.white)
                                .font(.sfRounded(size: .lg, weight: .medium))
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        Divider()
                            .frame(width: 370, height: 1)
                            .overlay(
                                Rectangle()
                                    .stroke(AppColors.lightGray.opacity(0.5), lineWidth: 0.5)
                            )
                    }
                    
                    // Account Settings Section
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Account Settings")
                            .font(.sfRounded(size: .xl, weight: .medium))
                            .foregroundColor(.white)
                        
                        NavigationLink(destination: AccountDetailsView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .frame(width: 24, height: 24, alignment: .center)
                                Text("Account Details")
                                    .font(.sfRounded(size: .lg, weight: .regular))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                        }
                        
                        NavigationLink(destination: Text("Settings")) {
                            HStack(spacing: 16) {
                                Image(systemName: "gear")
                                    .resizable()
                                    .frame(width: 24, height: 24, alignment: .center)
                                Text("Settings")
                                    .font(.sfRounded(size: .lg, weight: .regular))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 16) {
                            Image(systemName: "questionmark.circle")
                                .resizable()
                                .frame(width: 24, height: 24, alignment: .center)
                            Text("Support")
                                .font(.sfRounded(size: .lg, weight: .regular))
                            Spacer()
                            Image("discord")
                                .resizable()
                                .frame(width: 32, height: 32, alignment: .center)
                                .cornerRadius(8)
                            Text("@Discord Link")
                                .foregroundColor(AppColors.aquaGreen)
                                .font(.sfRounded(size: .lg, weight: .medium))
                        }
                        .foregroundColor(.white)
                        
                        // Logout Button
                        Button(action: userModel.logout) {
                            Text("Logout")
                                .font(.sfRounded(size: .lg, weight: .medium))
                                .foregroundColor(AppColors.red)
                                .padding(.bottom, 40)
                        }
                        
                        Text(serverBaseUrl).foregroundStyle(.white)
                            .font(.caption)
                    }
                    .padding()
                    
                    Spacer()
                    
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.black)
            .sheet(isPresented: $showOnrampView) {
                CoinbaseOnrampView()
            }
        }
    }
 
}

#Preview {
    @Previewable @StateObject var priceModel = SolPriceModel(mock: true)
    @Previewable @State var userId : String? = nil
    @StateObject var errorHandler = ErrorHandler()
    
    Group {
        if !priceModel.isReady || userId == nil {
            LoadingView(identifier: "AccountView - waiting for priceModel & userId")
        } else {
            AccountView()
                .environmentObject(UserModel(userId: userId!))
                .environmentObject(priceModel)
        }
    }
    .environmentObject(errorHandler)
}
