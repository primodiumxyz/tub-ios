//
//  BuySellFormView.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//
import SwiftUI

struct BuySellFormView: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var tokenModel: TokenModel
    @Binding var showBuySheet: Bool
    @Binding var defaultAmount: Double
    @State private var showBubbles = false
    @StateObject private var animationState = TokenAnimationState.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var isLoginPresented = false
    @State private var showOnrampView = false
    var handleBuy: (Double) -> Void
    var onSellSuccess: (() -> Void)?
    
    init (tokenModel: TokenModel, showBuySheet: Binding<Bool>, defaultAmount: Binding<Double>, handleBuy: @escaping (Double) -> Void, onSellSuccess: (() -> Void)? = nil) {
        self.tokenModel = tokenModel
        self._showBuySheet = showBuySheet
        self._defaultAmount = defaultAmount
        self.handleBuy = handleBuy
        self.onSellSuccess = onSellSuccess
    }
    
    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }
    
    func handleSell() {
        // Only trigger haptic feedback if vibration is enabled
        if settingsManager.isVibrationEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            print("🟢 Haptic feedback triggered")
        } else {
            print("🔴 Haptic feedback disabled")
        }
        
        guard let tokenPrice = tokenModel.prices.last?.priceUsd else {
            return
        }
        
        let priceLamps = priceModel.usdToLamports(usd: tokenPrice)
        userModel.sellTokens(price: priceLamps, completion: {result in
            switch result {
            case .success:
                animationState.showSellBubbles = true
                onSellSuccess?()
            case .failure(let error):
                notificationHandler.show(
                    error.localizedDescription,
                    type: .error
                )
            }
        })
    }
        func performAirdrop() {
        Network.shared.airdropNativeToUser(amount: 1 * Int(1e9)) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    notificationHandler.show(
                        "Airdrop successful!",
                        type: .success
                    )
                case .failure(let error):
                    notificationHandler.show(
                        error.localizedDescription,
                        type: .error
                    )
                }
            }
        }
        
        Network.shared.recordClientEvent(
            event: ClientEvent(
                eventName: "airdrop",
                source: "account_view",
                metadata: [
                    ["airdrop_amount": 1 * Int(1e9)]
                ]
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
        VStack {
            if userModel.userId == nil {
                Button {
					isLoginPresented = true
				} label: {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Login to Buy")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .foregroundColor(AppColors.black)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: 300)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.aquaGreen)
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .inset(by: 0.5)
                            .stroke(AppColors.aquaGreen, lineWidth: 1)
                    )
                }
            } else if activeTab == "buy" {
                if let balanceUsd = userModel.balanceLamps, priceModel.lamportsToUsd(lamports: balanceUsd) < 0.1  {
                    Button(action: {
                        // showOnrampView = true
                        performAirdrop()
                    }) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("Get 1 test SOL")
                                .font(.sfRounded(size: .xl, weight: .semibold))
                                .foregroundColor(AppColors.black)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: 300)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.aquaGreen)
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .inset(by: 0.5)
                                .stroke(AppColors.aquaGreen, lineWidth: 1)
                        )
                    }
                    .sheet(isPresented: $showOnrampView) {
                        CoinbaseOnrampView()
                    }
                } else {
                    // edit button
                    HStack(spacing: 16) {
                        Button(action: {
                            showBuySheet = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.aquaGreen)
                                .padding(12)
                                .background(Circle().stroke(AppColors.aquaGreen, lineWidth: 1))
                        }
                        
                        Button(action: {
                            handleBuy(settingsManager.defaultBuyValue)
                        }) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("Buy \(priceModel.formatPrice(usd: settingsManager.defaultBuyValue))")
                                    .font(.sfRounded(size: .xl, weight: .semibold))
                                    .foregroundColor(AppColors.black)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.aquaGreen)
                            .cornerRadius(30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .inset(by: 0.5)
                                    .stroke(AppColors.aquaGreen, lineWidth: 1)
                            )
                        }
                    }.padding(.horizontal,8)
                }
            } else {
                SellForm(tokenModel: tokenModel, showBuySheet: $showBuySheet, onSell: handleSell)
                    .padding(.horizontal,8)
            }
        }
		.padding(.bottom, 8)
		.sheet(isPresented: $isLoginPresented) {
			RegisterView(isRedirected: true)
				.background(.black)
		}
    }
}

// MARK: - Equatable Implementation

/// This extension adds custom equality comparison to BuySellFormView.
/// It's used to optimize SwiftUI's view updates by preventing unnecessary redraws.
extension BuySellFormView: Equatable {
    static func == (lhs: BuySellFormView, rhs: BuySellFormView) -> Bool {
        lhs.tokenModel.tokenId == rhs.tokenModel.tokenId
    }
}
