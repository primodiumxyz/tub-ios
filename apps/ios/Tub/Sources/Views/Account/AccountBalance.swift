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
			Group {
				if userModel.userId != nil {
					HStack(alignment: .bottom) {
						Text("Your Balance")
							.font(.sfRounded(size: .lg, weight: .semibold))
						
						Spacer()
						HStack(alignment: .center, spacing: 10) {
							if let usdcBalanceUsd = balances.usdcBalanceUsd {
								
								if balances.deltaUsd != 0 {
									let formattedChange = priceModel.formatPrice(
										usd: balances.deltaUsd,
										showSign: true,
										maxDecimals: 2
									)
									
									Text(formattedChange)
										.font(.sfRounded(size: .xs, weight: .light))
										.fontWeight(.bold)
										.foregroundStyle(balances.deltaUsd >= 0 ? .tubSuccess : .tubError)
										.opacity(0.7)
										.frame(height: 10)
										.padding(0)
								}
								else {
									Spacer().frame(height: 10)
								}
								
								let formattedBalance = priceModel.formatPrice(
									usd: usdcBalanceUsd + balances.tokenBalanceUsd,
									maxDecimals: 2,
									minDecimals: 2
								)
								
								Text(formattedBalance)
									.font(.sfRounded(size: .lg))
									.fontWeight(.bold)
								
							}
						}
					}
				} else {
					Text("Temp: Login to Start Trading")
						.font(.sfRounded(size: .lg, weight: .semibold))
						.multilineTextAlignment(.center)
				}
			}
			.padding(.bottom, 4)
			Divider()
				.frame(maxWidth: .infinity, maxHeight: 0.5)
				.background(.tubNeutral.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
    }
}
