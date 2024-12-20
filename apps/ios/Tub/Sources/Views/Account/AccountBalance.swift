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
    
    var deltaUsd : Double {
        guard let initialBalance  = userModel.initialPortfolioBalance, let currentBalanceUsd = userModel.portfolioBalanceUsd else { return 0 }
        return currentBalanceUsd - initialBalance
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Balance Section
            VStack(spacing: 4) {
                HStack(alignment: .center) {
                    Group {
                        if userModel.userId != nil {
                            HStack(alignment: .center, spacing: 10) {
                                Text("Your Balance")
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .lineLimit(1)
                            
                                if let balanceUsd = userModel.portfolioBalanceUsd {
                                    if deltaUsd != 0 {
                                        let formattedChange = priceModel.formatPrice(
                                            usd: deltaUsd,
                                            showSign: true,
                                            maxDecimals: 2
                                        )
                                        
                                        Text(formattedChange)
                                            .font(.sfRounded(size: .xs, weight: .light))
                                            .fontWeight(.bold)
                                            .foregroundStyle(deltaUsd >= 0 ? .tubSuccess : .tubError)
                                            .opacity(0.7)
                                            .frame(height: 10)
                                            .padding(0)
                                    }
                                    else {
                                        Spacer()
                                    }
                                    
                                    let formattedBalance = priceModel.formatPrice(
                                        usd: balanceUsd,
                                        maxDecimals: 2,
                                        minDecimals: 2
                                    )
                                    
                                    Text(formattedBalance)
                                        .font(.sfRounded(size: .lg))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.tubSuccess)
                                }
                            }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(.tubNeutral, lineWidth: 0.5)
                                )
                            
                            if userModel.userId != nil {
                                HStack(spacing: 8) {
                                    NavigationLink(destination: AccountView()) {
                                        ZStack {
                                            Circle()
                                                .stroke(.tubNeutral, lineWidth: 0.5)
                                                .frame(width: 44, height: 44)

                                            Image(systemName: "person.fill")
                                                .foregroundStyle(.tubNeutral)
                                                .font(.system(size: 18))
                                        }
                                    }
                                    
                                    // Share Button
                                    NavigationLink(destination: ShareView(
                                        tokenName: "TOKEN NAME",
                                        tokenSymbol: "USD",
                                        price: userModel.portfolioBalanceUsd ?? 0,
                                        priceChange: deltaUsd
                                    )) {
                                        ZStack {
                                            Circle()
                                                .stroke(.tubNeutral, lineWidth: 0.5)
                                                .frame(width: 44, height: 44)

                                            Image(systemName: "square.and.arrow.up")
                                                .foregroundStyle(.tubNeutral)
                                                .font(.system(size: 18))
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("Login")
                                .font(.sfRounded(size: .lg, weight: .semibold))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .foregroundStyle(.tubText)
            .padding(.horizontal, 12)
            .background(Color(UIColor.systemBackground))
        }
    }
}

#Preview {
    let userModel = UserModel.shared
    var priceModel : SolPriceModel {
        let model = SolPriceModel.shared
        spoofPriceModelData(model)
        return model
    }
    
    AccountBalanceView(userModel: userModel).environmentObject(priceModel)
}
