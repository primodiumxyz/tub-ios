//
//  AccountBalance.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import SwiftUI

struct AccountBalanceView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var userModel: UserModel
    @ObservedObject var currentTokenModel: TokenModel
    
    @State private var isExpanded: Bool = false
    
    var accountBalance: (tokens: Int, balance: Int?, change: Int) {
        //        let tokenValue = currentTokenModel.balanceLamps * (currentTokenModel.prices.last?.price ?? 0) / Int(1e9)
        let tokenValue = 0
        var balance : Int? = nil
        if let bal = userModel.balanceLamps {
            balance = bal + tokenValue
        }
        
        let adjustedChange = userModel.balanceChangeLamps + tokenValue
        
        return (tokenValue, balance, adjustedChange)
    }
    
    var body: some View {
        VStack(alignment: .center) {
            // Collapsed view
            
            if !isExpanded {
                VStack {
                    HStack {
                        if userModel.userId == nil {
                            Text("")
                        } else {
                            Text("Account Balance")
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundColor(AppColors.white)
                            
                            Spacer()
                            if let balance = accountBalance.balance, let balanceUsd = priceModel.formatPrice(lamports: balance, maxDecimals: 2, minDecimals: 2) {
                                Text(balanceUsd)
                                    .font(.sfRounded(size: .lg))
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.green)
                                    .padding(.trailing)
                                
                            } else {
                                LoadingBox(width: 80, height: 24)
                            }
                        }
                    }
                }
            }
            
            // Expanded view
            else {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Account Balance")
                                .font(.sfRounded(size: .sm, weight: .semibold))
                                .foregroundColor(AppColors.white)
                            
                            HStack {
                                if let balance = accountBalance.balance {
                                    Text("\(priceModel.formatPrice(lamports: balance, maxDecimals: 2, minDecimals: 2))")
                                        .font(.sfRounded(size: .xl2))
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.white)
                                } else {
                                    ProgressView()
                                }
                                
                                
                                Text("\(priceModel.formatPrice(lamports: accountBalance.change, showSign: true, maxDecimals: 2))")
                                
                                
                                // Format time elapsed
                                //                                    Text("\(formatDuration(Date.now))")
                                //                                        .foregroundColor(.gray)
                                //                                        .font(.sfRounded(size: .sm, weight: .regular))
                            }
                            .font(.sfRounded(size: .sm, weight: .semibold))
                            .foregroundColor(accountBalance.2 >= -10 ? AppColors.green : AppColors.red)
                        }
                        .padding(.horizontal,5)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    
                }
            }
        }
        .padding(.horizontal, 10)
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
    
    
}

