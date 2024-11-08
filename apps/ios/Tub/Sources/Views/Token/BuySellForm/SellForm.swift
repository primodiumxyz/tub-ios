//
//  SellForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct SellForm: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var tokenModel: TokenModel
    @Binding var showBuySheet: Bool
    var onSell : (((Bool) -> Void)?) -> ()

    private func handleSell() {
        let _ = onSell(nil)
    }

    private var tokenAmountView: some View {
        let tokenAmount = Int(Double(tokenModel.balanceLamps) / 1e9 * Double(tokenModel.prices.last?.price ?? 0))
        
        return VStack(alignment: .leading) {
            Text("You Own")
                .font(.sfRounded(size: .xs, weight: .semibold))
                .foregroundColor(AppColors.gray)
            
            Text("$\(priceModel.formatPrice(lamports: tokenAmount, showUnit: false, maxDecimals: 2))")
                .font(.sfRounded(size: .xl, weight: .semibold))
                .foregroundColor(AppColors.white)
            Text("\(priceModel.formatPrice(lamports: tokenModel.balanceLamps, showUnit: false)) \(tokenModel.token.symbol)")
                .font(.sfRounded(size: .sm, weight: .medium))
                .foregroundColor(AppColors.white.opacity(0.5))
        }
    }
    
    private var profitView: some View {
        let initialValueUsd = priceModel.lamportsToUsd(lamports: tokenModel.amountBoughtLamps)
        let currentValueLamps = Int(Double(tokenModel.balanceLamps) / 1e9 * Double(tokenModel.prices.last?.price ?? 0))
        let currentValueUsd = priceModel.lamportsToUsd(lamports: currentValueLamps)
        let gains = currentValueUsd - initialValueUsd
        let percentageGain = tokenModel.amountBoughtLamps > 0 ? gains / initialValueUsd * 100 : 0
        
        return Group {
            if tokenModel.amountBoughtLamps > 0 {
                VStack(alignment: .leading) {
                    Text("Profit")
                        .font(.sfRounded(size: .xs, weight: .semibold))
                        .foregroundColor(AppColors.gray)
                    
                    Text(priceModel.formatPrice(usd: gains, maxDecimals: 3))
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .foregroundColor(gains > 0 ? AppColors.green : AppColors.red)
                    
                    HStack(spacing: 2) {
                        Image(systemName: gains > 0 ? "arrow.up" : "arrow.down")
                            .foregroundColor(gains > 0 ? AppColors.green : AppColors.red)
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(String(format: "%.2f%%", percentageGain))
                            .font(.sfRounded(size: .sm, weight: .semibold))
                            .foregroundColor(gains > 0 ? AppColors.green : AppColors.red)
                    }
                }
                .frame(alignment: .leading)
            }
        }
    }
    
    private var sellButton: some View {
        Button(action: onSell) {
            Text("Sell")
                .font(.sfRounded(size: .xl, weight: .semibold))
                .foregroundColor(AppColors.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.primaryPink)
                .cornerRadius(30)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 16) {
                Button(action: {
                    showBuySheet = true
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Buy")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .foregroundColor(AppColors.primaryPink)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: 50)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.black)
                    .cornerRadius(26)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .inset(by: 0.5)
                            .stroke(AppColors.primaryPink, lineWidth: 1)
                    )
                }
                
                sellButton
                
            }.padding(.horizontal,16)
        }
        .frame(height: 50)
    }
}
