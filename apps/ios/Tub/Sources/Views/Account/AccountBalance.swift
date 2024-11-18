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
    
    var accountBalance: (totalBalance: Int?, change: Int) {
        guard  let solBalance = userModel.balanceLamps else {
            return (nil, 0)
        }
        var totalBalance: Int = solBalance
        var deltaBalance = userModel.balanceChangeLamps
        var tokenBalance = userModel.tokenBalanceLamps ?? 0
        
        let finalTokenBalance = tokenBalance * (currentTokenModel.prices.last?.price ?? 0) / Int(1e9)
        
        totalBalance += finalTokenBalance
        deltaBalance += finalTokenBalance
        tokenBalance = finalTokenBalance
        
        return (totalBalance, deltaBalance)
    }
    
    var body: some View {
        VStack(alignment: .center) {
            // Collapsed view
            
            if !isExpanded {
                VStack {
                    if userModel.userId == nil {
                        EmptyView()
                    } else {
                        HStack {
                            Text("Account Balance")
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundColor(AppColors.white)
                            
                            Spacer()
                            if let balance = accountBalance.totalBalance {
                                let balanceUsd = priceModel.formatPrice(lamports: balance, maxDecimals: 2, minDecimals: 2)
                                Text(balanceUsd)
                                    .font(.sfRounded(size: .lg))
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.green)
                                    .padding(.trailing)
                                    .frame(height:20)
                                
                            } else {
                                LoadingBox(width: 80, height: 20)
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
                                if let balance = accountBalance.totalBalance  {
                                    let formattedBalance = priceModel.formatPrice(lamports: balance, maxDecimals: 2, minDecimals: 2)
                                    Text(formattedBalance)
                                        .font(.sfRounded(size: .xl2))
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.white)
                                    
                                }
                                
                                let formattedChange = priceModel.formatPrice(lamports: accountBalance.change, showSign: true, maxDecimals: 2)
                                Text(formattedChange)
                                    .font(.sfRounded(size: .xl2))
                                    .fontWeight(.bold)
                                    .foregroundColor(accountBalance.change >= 0 ? AppColors.green : AppColors.red)
                            }
                            .font(.sfRounded(size: .sm, weight: .semibold))
                            .foregroundColor(accountBalance.change >= -10 ? AppColors.green : AppColors.red)
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

