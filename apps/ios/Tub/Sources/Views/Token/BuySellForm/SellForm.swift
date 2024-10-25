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
    var onSell : (((Bool) -> Void)?) -> ()

    private func handleSell() {
        let _ = onSell(nil)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("You Own")
                            .font(.sfRounded(size: .xs, weight: .semibold))
                            .foregroundColor(AppColors.gray)
                        
                        let tokenAmount = Int(Double(tokenModel.balance) / 1e9 * Double(tokenModel.prices.last?.price ?? 0))
                        
                        Text("$\(priceModel.formatPrice(lamports: tokenAmount, showUnit: false, maxDecimals: 2))")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .foregroundColor(AppColors.white)
                        Text("\(priceModel.formatPrice(lamports: tokenModel.balance, showUnit: false)) \(tokenModel.token.symbol)")
                            .font(.sfRounded(size: .sm, weight: .medium))
                            .foregroundColor(AppColors.white.opacity(0.5))
                    }
                        
                    
                    if tokenModel.amountBoughtLamps > 0 {
                        VStack(alignment: .leading) {
                            Text("Profit")
                                .font(.sfRounded(size: .xs, weight: .semibold))
                                .foregroundColor(AppColors.gray)
                            
                            let initialValueUsd = priceModel.lamportsToUsd(lamports: tokenModel.amountBoughtLamps)
                            let currentValueLamps = Int(Double(tokenModel.balance) / 1e9 * Double(tokenModel.prices.last?.price ?? 0))
                            let currentValueUsd = priceModel.lamportsToUsd(lamports: currentValueLamps)

                            let gains = currentValueUsd - initialValueUsd
                            
                            let percentageGain = tokenModel.amountBoughtLamps > 0 ? gains / initialValueUsd * 100 : 0
                            
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
                .padding(.horizontal)
                
                Button(action: handleSell) {
                    Text("Sell")
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(AppColors.primaryPink)
                        .cornerRadius(26)
                }
                
                Spacer()
            }
        }.frame(height:100)
    }
}
