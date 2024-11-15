//
//  BuySellForm.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//
import SwiftUI

struct BuySellForm: View {
    @EnvironmentObject private var errorHandler: ErrorHandler
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var tokenModel: TokenModel
    @Binding var activeTab: String
    @Binding var showBuySheet: Bool
    @Binding var defaultAmount: Double
    @State private var showBubbles = false
    @StateObject private var animationState = TokenAnimationState.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var navigateToLogin = false
    @State private var showOnrampView = false
    
    var handleBuy: (Double) -> Void
    var onSellSuccess: () -> Void
    
    func handleSell() {
        // Only trigger haptic feedback if vibration is enabled
        if settingsManager.isVibrationEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            print("🟢 Haptic feedback triggered")
        } else {
            print("🔴 Haptic feedback disabled")
        }
        
//        tokenModel.sellTokens(completion: {result in
//            switch result {
//            case .success:
//                animationState.showSellBubbles = true
//                activeTab = "buy"
//                onSellSuccess()
//            case .failure(let error):
//                errorHandler.show(error)
//            }
//        })
    }
    
    var body: some View {
        VStack {
            if userModel.userId == nil {
                NavigationLink(destination: RegisterView(isRedirected: true)
                    .background(.black)
                , isActive: $navigateToLogin) {
                    EmptyView()
                }
                
                Button(action: {
                    navigateToLogin = true
                }) {
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
                if userModel.balanceLamps == 0 {
                    Button(action: {
                        showOnrampView = true
                    }) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("Deposit")
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
        }.padding(.bottom, 8)
    }
}

// MARK: - Equatable Implementation

/// This extension adds custom equality comparison to BuySellForm.
/// It's used to optimize SwiftUI's view updates by preventing unnecessary redraws.
extension BuySellForm: Equatable {
    static func == (lhs: BuySellForm, rhs: BuySellForm) -> Bool {
        lhs.tokenModel.tokenId == rhs.tokenModel.tokenId
    }
}
