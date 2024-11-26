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

    var balances: (usdcBalanceUsd: Double?, tokenBalanceUsd: Double, deltaUsd: Double) {
        let usdcBalanceUsd =
            userModel.balanceUsdc == nil
            ? nil : priceModel.usdcToUsd(usdc: userModel.balanceUsdc!)
        let tokenBalanceUsd =
            userModel.balanceToken == nil
            ? 0
            : Double(userModel.balanceToken!) * (currentTokenModel.prices.last?.priceUsd ?? 0) / 1e9

        let deltaUsd =
            (tokenBalanceUsd) + priceModel.usdcToUsd(usdc: userModel.balanceChangeUsdc)

        return (usdcBalanceUsd, tokenBalanceUsd, deltaUsd)
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
                        .foregroundColor(Color.white)

                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        if let balanceUsdc = balances.usdcBalanceUsd {
                            if balances.deltaUsd != 0 {
                                let formattedChange = priceModel.formatPrice(
                                    usd: balances.deltaUsd,
                                    showSign: true,
                                    maxDecimals: 2
                                )
                                Text(formattedChange)
                                    .font(.sfRounded(size: .xs, weight: .light))
                                    .fontWeight(.bold)
                                    .foregroundColor(balances.deltaUsd >= 0 ? Color.green : Color.red)
                                    .opacity(0.7)
                                    .frame(height: 10)
                                    .padding(0)
                            }
                            else {
                                Spacer().frame(height: 10)
                            }

                            let formattedBalance = priceModel.formatPrice(
                                usd: balanceUsdc + balances.tokenBalanceUsd,
                                maxDecimals: 2,
                                minDecimals: 2
                            )
                            Text(formattedBalance)
                                .font(.sfRounded(size: .lg))
                                .fontWeight(.bold)
                                .foregroundColor(Color.white)

                        }
                    }
                }.padding(.horizontal, 16)
            }
            Divider()
                .frame(width: 340.0, height: 1.0)
                .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.2))
                .padding(0)
        }

        .background(Color.black)
    }
}
