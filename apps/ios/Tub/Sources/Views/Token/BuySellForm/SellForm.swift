//
//  SellForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct SellForm: View {
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
                        Text("\(tokenModel.tokenBalance, specifier: "%.2f") \(tokenModel.token.symbol)")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .foregroundColor(AppColors.white)
                    }
                    
                    
                    VStack(alignment: .leading) {
                        Text("Profit")
                            .font(.sfRounded(size: .xs, weight: .semibold))
                            .foregroundColor(AppColors.gray)
                        
                        let gains = tokenModel.tokenBalance * (tokenModel.prices.last?.price ?? 0) - tokenModel.amountBoughtSol
                        let percentageGain = gains / tokenModel.amountBoughtSol * 100
                        
                        HStack(){
                            Image(systemName: gains > 0 ? "arrow.up" : "arrow.down")
                                .foregroundColor(gains > 0 ? AppColors.green : AppColors.red)
                                .font(.system(size: 16, weight: .bold))
                            
                            Text(String(format: "$%.2f", gains))
                                .font(.sfRounded(size: .xl, weight: .semibold))
                                .foregroundColor(gains > 0 ? AppColors.green : AppColors.red)
                                .offset(x:-5)
                            Text(String(format: "(%.2f%%)", percentageGain))
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundColor(gains > 0 ? AppColors.green : AppColors.red)
                                .offset(x:-8)
                        }
                    }
                    .frame(width: geometry.size.width * 0.6, alignment: .leading)
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

