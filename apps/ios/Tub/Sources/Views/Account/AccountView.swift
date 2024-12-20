//
//  AccountView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @State private var isNavigatingToRegister = false
    @State private var isAirdropping = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showOnrampView = false
    @State private var showWithdrawView = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        Group {
            if userModel.userId != nil {
                VStack(spacing: 18) {
                    BalanceSection()
                    ActionButtons(
                        isAirdropping: isAirdropping,
                        showOnrampView: $showOnrampView,
                        showWithdrawView: $showWithdrawView
                    )
                    
                    TokenHistoryPreview()
                    
                    AccountSettingsView()
                    Spacer()
                }
            }
            else {
                RegisterView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showWithdrawView) {
            WithdrawView()
                .withNotificationBanner()
        }
        .sheet(isPresented: $showOnrampView) {
            CoinbaseOnrampView()
                .withNotificationBanner()
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(UIColor.systemBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        
    }
}

// New component for the balance section
private struct BalanceSection: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    
    var deltaUsd : Double {
        guard let initialBalance  = userModel.initialPortfolioBalance, let currentBalanceUsd = userModel.portfolioBalanceUsd else { return 0 }
        return currentBalanceUsd - initialBalance
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Account Balance")
                .font(.sfRounded(size: .lg, weight: .regular))
                .foregroundStyle(.secondary)
            
            if let balance = userModel.portfolioBalanceUsd {
                let formattedBalance = priceModel.formatPrice(usd: balance, maxDecimals: 2, minDecimals: 2)
                
                Text(formattedBalance)
                    .font(.sfRounded(size: .xl5, weight: .bold))
                    .foregroundStyle(.primary)
            }
            else {
                ProgressView()
            }
            
            if deltaUsd > 0 {
                Text("\(priceModel.formatPrice(usd: deltaUsd, showSign: true, maxDecimals: 2))")
                
                // Format time elapsed
                Text("\(formatDuration(userModel.elapsedSeconds))")
                    .foregroundStyle(.secondary)
                    .font(.sfRounded(size: .sm, weight: .regular))
                
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}


private struct TokenHistoryPreview: View {
    @EnvironmentObject private var userModel: UserModel
    @State private var height: CGFloat? = 0
  
    func handleRefreshTxs () {
        Task {
            try? await userModel.refreshTxs()
        }
    }
    
    var body: some View {
        VStack {
            if userModel.txs == nil || userModel.txs?.count == 0 {
                EmptyView()
            } else {
                NavigationLink(destination: HistoryView()) {
                    VStack(alignment: .leading) {
                        Rectangle()
                            .fill(.tubText.opacity(0.3))
                            .frame(height: 1)
                            .padding(.bottom, 8)
                        HStack {
                            Text("Last Trade")
                                .font(.sfRounded(size: .lg, weight: .regular))
                            Spacer()
                            Text("View All")
                                .font(.sfRounded(size: .base, weight: .regular))
                            Image(systemName: "chevron.right")
                        }.foregroundStyle(.tubText)
                        
                        if let txs = userModel.txs, txs.count > 0 {
                            TransactionRow(transaction: txs[0])
                                .frame(height: 40)
                        } else {
                            HStack{
                                Spacer()
                                ProgressView().frame(maxHeight: 40)
                                Spacer()
                            }
                        }
                        
                        Rectangle()
                            .fill(.tubText.opacity(0.3))
                            .frame(height: 1)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .frame(height: height)
        .clipped()
        .padding(.horizontal)
        .onAppear{
            handleRefreshTxs()
        }
        .onChange(of: userModel.walletAddress) { handleRefreshTxs() }
        .onChange(of : userModel.txs) {
            withAnimation(.easeInOut(duration: 0.3)) {
                height = userModel.txs == nil || userModel.txs?.count == 0 ? 0 : nil
            }
        }
    }
}

private struct TransactionRow: View {
    let transaction: TransactionData
    @EnvironmentObject private var priceModel: SolPriceModel

    var body: some View {
        HStack {
            ImageView(imageUri: transaction.imageUri, size: 40)
                .cornerRadius(8)

            VStack(alignment: .leading) {
                HStack {
                    Text(transaction.isBuy ? "Buy" : "Sell")
                        .font(.sfRounded(size: .lg, weight: .bold))
                        .foregroundStyle(.tubNeutral)
                    Text(transaction.name.isEmpty ? transaction.mint.truncatedAddress() : transaction.name)
                        .font(.sfRounded(size: .lg, weight: .bold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .offset(x: -2)
                }


            }
            Spacer()
            VStack(alignment: .trailing) {
                let price = priceModel.formatPrice(usdc: transaction.valueUsdc, showSign: true)
                Text(price)
                    .font(.sfRounded(size: .base, weight: .bold))
                    .foregroundStyle(transaction.isBuy ? Color.red : Color.green)

                let quantity = priceModel.formatPrice(
                    lamports: abs(transaction.quantityTokens),
                    showUnit: false
                )
                HStack {
                    Text(quantity)
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(.secondary)
                        .offset(x: 4, y: 2)

                    Text(transaction.symbol)
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(.secondary)
                        .offset(y: 2)
                }
            }
        }
    }
}

// New component for action buttons
private struct ActionButtons: View {
    let isAirdropping: Bool
    @Binding var showOnrampView: Bool
    @Binding var showWithdrawView: Bool
    
    var body: some View {
        HStack(spacing: 24) {
            Spacer()
            
            // Add Transfer Button
            VStack(spacing: 8) {
                CircleButton(
                    icon: "arrow.left.arrow.right",
                    color: .tubAccent,
                    iconSize: 22,
                    action: { showWithdrawView.toggle() }
                )
                
                Text("Transfer")
                    .font(.sfRounded(size: .sm, weight: .medium))
                    .foregroundStyle(.tubAccent)
                    .multilineTextAlignment(.center)
            }.frame(width: 90)
            
            // Add Funds Button
            VStack(spacing: 8) {
                CircleButton(
                    icon: "plus",
                    color: .tubAccent,
                    action: { showOnrampView = true }
                )
                
                Text("Add Funds")
                    .font(.sfRounded(size: .sm, weight: .medium))
                    .foregroundStyle(.tubAccent)
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
                .foregroundStyle(.primary)
            
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
                .foregroundStyle(Color.primary)
            }
            
            NavigationLink(destination: PortfolioView()) {
                HStack(spacing: 16) {
                    Image(systemName: "book.circle")
                        .resizable()
                        .frame(width: 24, height: 24, alignment: .center)
                    Text("Portfolio")
                        .font(.sfRounded(size: .lg, weight: .regular))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(Color.primary)
            }
            
            
            
            
            NavigationLink(destination: SettingsView()) {
                HStack(spacing: 16) {
                    Image(systemName: "gear")
                        .resizable()
                        .frame(width: 24, height: 24, alignment: .center)
                    Text("Preferences")
                        .font(.sfRounded(size: .lg, weight: .regular))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(Color.primary)
            }
            
            HStack(spacing: 16) {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .frame(width: 24, height: 24, alignment: .center)
                Text("Support")
                    .font(.sfRounded(size: .lg, weight: .regular))
                Spacer()
                Image("Discord")
                    .resizable()
                    .frame(width: 32, height: 32, alignment: .center)
                    .cornerRadius(8)
                    .padding(.trailing, -4)
                Text("Discord Server")
                    .font(.sfRounded(size: .lg, weight: .medium))
            }
            .foregroundStyle(.primary)
            
            // Logout Button
            IconTextButton(
                icon: "rectangle.portrait.and.arrow.right",
                text: "Logout",
                textColor: Color.red,
                action: { userModel.logout() }
            )
            
        }
        .padding()
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @Previewable @StateObject var userModel = UserModel.shared
    @Previewable @StateObject var priceModel = {
        let model = SolPriceModel.shared
        spoofPriceModelData(model)
        return model
    }()
    
    @Previewable @StateObject var notificationHandler = NotificationHandler()
    
    NavigationStack {
        AccountView()
    }
    .environmentObject(priceModel)
    .environmentObject(userModel)
    .environmentObject(notificationHandler)
}
