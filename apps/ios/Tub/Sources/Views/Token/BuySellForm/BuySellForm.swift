//
//  BuySellForm.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//
import SwiftUI

struct BuySellForm: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var tokenModel: TokenModel
    @Binding var activeTab: String
    @Binding var showBuySheet: Bool
    @Binding var defaultAmount: Double
    
    func handleSell(completion: ((Bool) -> Void)?) {
        tokenModel.sellTokens(completion: {success in
            if success {
                activeTab = "buy"
            }
            completion?(success)
        })
    }
    
    func handleBuy(amount: Double) {
        let buyAmountLamps = priceModel.usdToLamports(usd: amount)
        tokenModel.buyTokens(buyAmountLamps: buyAmountLamps) { success in
            if success {
                activeTab = "sell" // Switch tab after successful buy
            }
        }
    }
    
    var body: some View {
        VStack {
        if userModel.userId == "" {
            Text("Register to trade")
                .font(.title)
                .foregroundColor(.yellow)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
        } else if activeTab == "buy" {
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
                        handleBuy(amount: defaultAmount)
                    }) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("Buy $\(String(format: "%.2f", defaultAmount))")
                                .font(.sfRounded(size: .xl, weight: .semibold))
                                .foregroundColor(AppColors.aquaGreen)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.black)
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .inset(by: 0.5)
                                .stroke(AppColors.aquaGreen, lineWidth: 1)
                        )
                    }
                }.padding(.horizontal,16)
            } else {
                SellForm(tokenModel: tokenModel, onSell: handleSell)
            }
        }
            
//        .overlay(
//            Group {
//                if showBuySheet {
//                    Color.black.opacity(0.4)
//                        .ignoresSafeArea()
//                        .onTapGesture {
//                            withAnimation(.easeInOut(duration: 0.3)) {
//                                showBuySheet = false
//                            }
//                        }
//                    
//                    BuyForm(
//                        isVisible: $showBuySheet,
//                        defaultAmount: $defaultAmount,
//                        tokenModel: tokenModel,
//                        onBuy: { amount in
//                            handleBuy(amount: amount)
//                            showBuySheet = false
//                        }
//                    )
//                    .transition(.move(edge: .bottom))
//                    .zIndex(2)
//                    .offset(y: showBuySheet ? 0 : UIScreen.main.bounds.height)
//                    .animation(.easeInOut(duration: 0.3), value: showBuySheet)
//                }
//            }
//        )
    }
}

#Preview {
    
    @Previewable @AppStorage("userId") var userId: String = ""
    @Previewable @State var activeTab: String = "buy"
    @Previewable @State var showSheet = false
    @ObservedObject var  tokenModel = TokenModel(userId: userId, tokenId: mockTokenId)
    @State var defaultAmount: Double = 50.0

    VStack {
        BuySellForm(
            tokenModel: tokenModel,
            activeTab: $activeTab,
            showBuySheet: $showSheet,
            defaultAmount: $defaultAmount
        )
        .environmentObject(UserModel(userId: userId))
        .environmentObject(SolPriceModel(mock: true))
        // Buy Sheet View
        if showSheet {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSheet = false
                    }
                }

            BuyForm(
                isVisible: $showSheet,
                defaultAmount: $defaultAmount,
                tokenModel: tokenModel,
                onBuy: { amount in
                    showSheet = false
                }
            )
            .transition(.move(edge: .bottom))
            .zIndex(2) // Ensure it stays on top of everything
            .offset(y: -200)
            .environmentObject(SolPriceModel(mock: true))
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
    .foregroundColor(.white)
}

// MARK: - Equatable Implementation

/// This extension adds custom equality comparison to BuySellForm.
/// It's used to optimize SwiftUI's view updates by preventing unnecessary redraws.
extension BuySellForm: Equatable {
    static func == (lhs: BuySellForm, rhs: BuySellForm) -> Bool {
        lhs.tokenModel.tokenId == rhs.tokenModel.tokenId
    }
}
