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
    @Environment(\.presentationMode) var presentationMode
    @State private var showOnrampView = false
    @State private var errorMessage: String = ""
    

    
    func performAirdrop() {
        isAirdropping = true
        
        Network.shared.airdropNativeToUser(amount: 1 * Int(1e9)) { result in
            DispatchQueue.main.async {
                isAirdropping = false
                switch result {
                case .success:
                    errorHandler.showSuccess("Airdrop successful!")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    errorHandler.show(error)
                }
            }
        }
        
        Network.shared.recordClientEvent(
            event: ClientEvent(
                eventName: "airdrop",
                source: "account_view",
                metadata: [
                    ["airdrop_amount": 1 * Int(1e9)]
                ],
                errorDetails: errorMessage
            )
        ) { result in
            switch result {
            case .success:
                print("Successfully recorded buy event")
            case .failure(let error):
                print("Failed to record buy event: \(error)")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if userModel.userId != nil  {
                    AccountContentView(
                        isAirdropping: $isAirdropping,
                        showOnrampView: $showOnrampView,
                        performAirdrop: performAirdrop
                    )
                } else {
                    UnregisteredAccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.black)
            .sheet(isPresented: $showOnrampView) {
                    
                    VStack {
                        HStack {
                            Text("Deposit")
                                .font(.sfRounded(size: .xl, weight: .semibold))
                                .foregroundColor(AppColors.white)
                            Spacer()
                            Button(action: { showOnrampView = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(AppColors.white)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }.padding(24)
                        
                        CoinbaseOnrampView()
                    }.background(AppColors.black)
            }
            .presentationDragIndicator(.visible)
            .presentationBackground(.black)
        }
    }
}

// New component for the header section
private struct AccountHeaderView: View {
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Account")
                .font(.sfRounded(size: .xl2, weight: .semibold))
                .foregroundColor(AppColors.white)
            
            BalanceSection()
        }
    }
}

// New component for the balance section
private struct BalanceSection: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    
    var accountBalance: (balance: Int?, change: Int) {
        let balance = userModel.balanceLamps
        
        let adjustedChange = userModel.balanceChangeLamps
        
        return (balance, adjustedChange)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Account Balance")
                .font(.sfRounded(size: .lg, weight: .regular))
                .foregroundColor(AppColors.lightGray.opacity(0.7))
            
            if let balance = accountBalance.balance {
                
            
            Text("\(priceModel.formatPrice(lamports: balance, maxDecimals: 2, minDecimals: 2))")
                .font(.sfRounded(size: .xl5, weight: .bold))
                .foregroundColor(.white)
            } else {
                ProgressView()
            }
            
            if accountBalance.change > 0  {
                  Text("\(priceModel.formatPrice(lamports: accountBalance.change, showSign: true, maxDecimals: 2))")
                                    
                                    // Format time elapsed
//                                    Text("\(formatDuration(userModel.timeElapsed))")
//                                        .foregroundColor(.gray)
//                                        .font(.sfRounded(size: .sm, weight: .regular))
                
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

// New component for action buttons
private struct ActionButtonsView: View {
    let isAirdropping: Bool
    let performAirdrop: () -> Void
    @Binding var showOnrampView: Bool
    
    var body: some View {
        HStack(spacing: 24) {
            Spacer()
            
            // Airdrop Button
            VStack(spacing: 8) {
                Button(action: performAirdrop) {
                    ZStack {
                        Circle()
                            .stroke(AppColors.primaryPink, lineWidth: 1)
                            .frame(width: 50, height: 50)
                        
                        if isAirdropping {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane")
                                .foregroundColor(AppColors.primaryPink)
                                .font(.system(size: 24))
                        }
                    }
                }.disabled(isAirdropping)
                
                Text("Get $200")
                    .font(.sfRounded(size: .sm, weight: .medium))
                    .foregroundColor(AppColors.primaryPink)
                    .multilineTextAlignment(.center)
            }.frame(width: 90)
            
            // Add Transfer Button
            VStack(spacing: 8) {
                Button(action: {} ) {
                    ZStack {
                        Circle()
                            .stroke(AppColors.aquaGreen, lineWidth: 1)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundColor(AppColors.aquaGreen)
                            .font(.system(size: 22))
                    }
                }.disabled(true)
                
                Text("Transfer")
                    .font(.sfRounded(size: .sm, weight: .medium))
                    .foregroundColor(AppColors.aquaGreen)
                    .multilineTextAlignment(.center)
            }.frame(width: 90).opacity(0.7)
            
            // Add Funds Button
            VStack(spacing: 8) {
                Button(action: { showOnrampView = true }) {
                    ZStack {
                        Circle()
                            .stroke(AppColors.aquaGreen, lineWidth: 1)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.aquaGreen)
                            .font(.system(size: 24))
                    }
                }
                
                Text("Add Funds")
                    .font(.sfRounded(size: .sm, weight: .medium))
                    .foregroundColor(AppColors.aquaGreen)
                    .multilineTextAlignment(.center)
            }.frame(width: 90)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// New component for account settings
private struct AccountSettingsView: View {
    @EnvironmentObject private var userModel: UserModel

    var body: some View {
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
            
            NavigationLink(destination: SettingsView()) {
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
                    .padding(.trailing, -4)
                Text("@Discord Link")
                    .foregroundColor(AppColors.aquaGreen)
                    .font(.sfRounded(size: .lg, weight: .medium))
            }
            .foregroundColor(.white)
            
            // Logout Button
            Button(action: userModel.logout) {
                HStack(spacing: 16) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .resizable()
                        .frame(width: 22, height: 22, alignment: .center)
                        .foregroundColor(AppColors.red)
                        .padding(.bottom, 40)
                        .padding(.leading, 4)
                        .padding(.trailing, 2)
                    
                    
                    Text("Logout")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundColor(AppColors.red)
                        .padding(.bottom, 40)
                }
            }
            
            Text(serverBaseUrl).foregroundStyle(.white)
                .font(.caption)
        }
        .padding()
    }
}

// New component for unregistered users
private struct UnregisteredAccountView: View {
    var body: some View {
            RegisterView().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Main content view for registered users
private struct AccountContentView: View {
    @Binding var isAirdropping: Bool
    @Binding var showOnrampView: Bool
    let performAirdrop: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            AccountHeaderView()
            ActionButtonsView(
                isAirdropping: isAirdropping,
                performAirdrop: performAirdrop,
                showOnrampView: $showOnrampView
            )
            AccountSettingsView()
            Spacer()
        }
    }
}
