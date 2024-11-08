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
        
        if userModel.balanceLamps >= buyAmountLamps {
            tokenModel.buyTokens(buyAmountLamps: buyAmountLamps) { success in
                if success {
                    activeTab = "sell" // Switch tab after successful buy
                }
            }
        } else {
            print("Insufficient balance to complete the purchase.")
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
                            Text("Buy \(priceModel.formatPrice(usd: defaultAmount))")
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
                }.padding(.horizontal,16)
            } else {
                SellForm(tokenModel: tokenModel, onSell: handleSell)
            }
        }
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
