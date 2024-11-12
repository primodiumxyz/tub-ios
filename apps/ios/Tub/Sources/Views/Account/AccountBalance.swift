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
    
    var accountBalance: Int {
        let tokenValue = currentTokenModel.balanceLamps * (currentTokenModel.prices.last?.price ?? 0) / Int(1e9)
        return tokenValue + userModel.balanceLamps
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // Collapsed view
            if !isExpanded {
                HStack {
                    Text("Account Balance")
                        .font(.sfRounded(size: .base, weight: .semibold))
                        .foregroundColor(AppColors.white)
                    
                    Spacer()
                    
                    Text("\(priceModel.formatPrice(lamports: accountBalance, maxDecimals: 2, minDecimals: 2))")
                        .font(.sfRounded(size: .lg))
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.green)
                        .padding(.trailing)
                    
                    Image("Vector")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.vertical, 6.0)
            }
            
            // Expanded view
            else {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Account Balance")
                            .font(.sfRounded(size: .sm, weight: .semibold))
                            .foregroundColor(AppColors.white)
                        
                        Text("\(priceModel.formatPrice(lamports: accountBalance, maxDecimals: 2, minDecimals: 2))")
                            .font(.sfRounded(size: .xl2))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.white)
                        
                        let tokenValue = currentTokenModel.balanceLamps * (currentTokenModel.prices.last?.price ?? 0) / Int(1e9)
                        let adjustedChange = userModel.balanceChangeLamps + tokenValue
                        
                        HStack {
                            Text("\(priceModel.formatPrice(lamports: adjustedChange, showSign: true, maxDecimals: 2))")
                            
                            let adjustedPercentage = userModel.initialBalanceLamps != 0  ? 100 - (Double(userModel.balanceLamps) / Double(userModel.initialBalanceLamps)) * 100 : nil;
                            
                            if let pct = adjustedPercentage {
                                Text("(\(abs(pct), specifier: "%.1f")%)")
                            }
                            
                            // Format time elapsed
                            Text("\(formatDuration(userModel.timeElapsed))")
                                .foregroundColor(.gray)
                                .font(.sfRounded(size: .sm, weight: .regular))
                        }
                        .font(.sfRounded(size: .sm, weight: .semibold))
                        .foregroundColor(adjustedChange >= 0 ? AppColors.green : AppColors.red)
                    }
                    .padding()
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                    Spacer()
                    
                    Image("Vector")
                        .resizable()
                        .frame(width: 44, height: 36)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.trailing)
                .padding(.vertical, 3.0)
            }
        }
        .padding(.horizontal, 16)
        .background(AppColors.darkgray)
        .cornerRadius(40)
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
    

}

