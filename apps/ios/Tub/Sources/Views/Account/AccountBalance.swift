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

    var balances: (solBalanceUsd: Double?, tokenBalanceUsd: Double, deltaUsd: Double) {
        let solBalanceUsd =
            userModel.balanceLamps == nil
            ? nil : priceModel.lamportsToUsd(lamports: userModel.balanceLamps!)
        let tokenBalanceUsd =
            userModel.tokenBalanceLamps == nil
            ? 0
            : Double(userModel.tokenBalanceLamps!) * (currentTokenModel.prices.last?.priceUsd ?? 0) / 1e9

        let deltaUsd =
            (tokenBalanceUsd) + priceModel.lamportsToUsd(lamports: userModel.balanceChangeLamps)

        return (solBalanceUsd, tokenBalanceUsd, deltaUsd)
    }

    var body: some View {
        VStack(spacing: 4) {
            if userModel.userId == nil {
                EmptyView()
            }
            else {
                HStack(alignment: .bottom) {
                    Text("Your Balance")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()
                    HStack(alignment: .center, spacing: 10) {
                        if let balance = balances.solBalanceUsd {
                        
                            if balances.deltaUsd != 0 {
                                let formattedChange = priceModel.formatPrice(
                                    usd: balances.deltaUsd,
                                    showSign: true,
                                    maxDecimals: 2
                                )
                                
                                Text(formattedChange)
                                    .font(.sfRounded(size: .xs, weight: .light))
                                    .fontWeight(.bold)
                                    .foregroundStyle(balances.deltaUsd >= 0 ? Color.green : Color.red)
                                    .opacity(0.7)
                                    .frame(height: 10)
                                    .padding(0)
                            }
                            else {
                                Spacer().frame(height: 10)
                            }
                            
                            let formattedBalance = priceModel.formatPrice(
                                usd: balance,
                                maxDecimals: 2,
                                minDecimals: 2
                            )
                            
                            Text(formattedBalance)
                                .font(.sfRounded(size: .lg))
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            }
            Divider()
                .frame(width: 340.0, height: 1.0)
                .background(.secondary)
                .padding(0)
        }

        .background(Color(UIColor.systemBackground))
    }
}
