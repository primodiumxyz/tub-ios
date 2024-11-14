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
        VStack(alignment: .center) {
            
            // Collapsed view
            if !isExpanded {
                VStack {
                    HStack {
                        Text("Account Balance")
                            .font(.sfRounded(size: .base, weight: .semibold))
                            .foregroundColor(AppColors.white)
                        
                        Spacer()
                        
                        let tokenValue = 0
                        Text("\(priceModel.formatPrice(lamports: userModel.balanceLamps + tokenValue, maxDecimals: 2, minDecimals: 2))")
                            .font(.sfRounded(size: .lg))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.green)
                            .padding(.trailing)
                        
                        Image("Vector")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(.trailing)
                    }
                    .padding(.horizontal,10)
                    .padding(.vertical,8)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                
                Divider()
                    .frame(width: 300, height: 1)
                    .overlay(
                        Rectangle()
                            .stroke(AppColors.lightGray.opacity(0.3), lineWidth: 0.5)
                    )
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
                            
                            //    let tokenValue = currentTokenModel.balanceLamps * (currentTokenModel.prices.last?.price ?? 0) / Int(1e9)
                            let tokenValue = 0
                            Text("\(priceModel.formatPrice(lamports: userModel.balanceLamps + tokenValue, maxDecimals: 2, minDecimals: 2))")
                                .font(.sfRounded(size: .xl2))
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.white)
                            
                            let adjustedChange = userModel.balanceChangeLamps + tokenValue
                            
                            HStack {
                                Text("\(priceModel.formatPrice(lamports: adjustedChange, showSign: true, maxDecimals: 2))")
                                
                                let adjustedPercentage = userModel.initialBalanceLamps != 0  ? 100 - (Double(userModel.balanceLamps) / Double(userModel.initialBalanceLamps)) * 100 : 100;
                                Text("(\(abs(adjustedPercentage), specifier: "%.1f")%)")
                                
                                // Format time elapsed
                                Text("\(formatDuration(userModel.timeElapsed))")
                                    .foregroundColor(.gray)
                                    .font(.sfRounded(size: .sm, weight: .regular))
                            }
                            .font(.sfRounded(size: .sm, weight: .semibold))
                            .foregroundColor(adjustedChange >= 0 ? AppColors.green : AppColors.red)
                        }
                        .padding(.horizontal,5)
                        .padding(.top,5)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.toggle()
                            }                        
                        }
                        Spacer()
                        
                        Image("Vector")
                            .resizable()
                            .frame(width: 44, height: 36)
                            .padding(.trailing)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    Divider()
                        .frame(width: 300, height: 1)
                        .overlay(
                            Rectangle()
                                .stroke(AppColors.lightGray.opacity(0.3), lineWidth: 0.5)
                        )
                        .offset(y:-3)
                }
            }
        }
        .background(Color.clear)
        .cornerRadius(30)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
    

}

