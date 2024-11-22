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
        VStack(spacing: 0.5) {
            if userModel.userId == nil {
                EmptyView()
            }
            else {
                HStack(alignment: .top) {
                    Text("Your Balance")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                        .foregroundColor(AppColors.white)

                    Spacer()
                    VStack(alignment: .trailing) {
                        if let balance = balances.solBalanceUsd {
                            let formattedBalance = priceModel.formatPrice(
                                usd: balance,
                                maxDecimals: 2,
                                minDecimals: 2
                            )
                            Text(formattedBalance)
                                .font(.sfRounded(size: .lg))
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.white)

                            let formattedChange = priceModel.formatPrice(
                                usd: balances.deltaUsd,
                                showSign: true,
                                maxDecimals: 2
                            )
                            Text(formattedChange)
                                .font(.sfRounded(size: .xs, weight: .light))
                                .fontWeight(.bold)
                                .foregroundColor(balances.deltaUsd >= 0 ? AppColors.green : AppColors.red)
                        }
                    }
                }
            }
            Divider()
                .frame(width: 340.0, height: 1.0)
                .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.2))
                .padding(0)
        }

        .background(Color.black)
    }
}
