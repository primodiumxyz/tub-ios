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
	@StateObject private var activityManager = LiveActivityManager.shared

    private func updateLiveActivity() {
        if activityManager.isActivityActive, let balanceUsd = userModel.portfolioBalanceUsd {
            activityManager.updateActivity(newValue: balanceUsd, trend: deltaUsd)
        }
    }
    
    var deltaUsd : Double {
        guard let initialBalance  = userModel.initialPortfolioBalance, let currentBalanceUsd = userModel.portfolioBalanceUsd else { return 0 }
        return currentBalanceUsd - initialBalance
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
									Spacer().frame(height: 10)
								}
								
								let formattedBalance = priceModel.formatPrice(
									usd: balanceUsd,
									maxDecimals: 2,
									minDecimals: 2
								)
								
								Text(formattedBalance)
									.font(.sfRounded(size: .lg))
									.fontWeight(.bold)
									.onAppear {
										// Start Live Activity when balance first appears
										if !activityManager.isActivityActive {
											activityManager.startActivity(
												name: "Account Balance",
												symbol: "USD",
												initialValue: balanceUsd
											)
										}
									}
								
								// Start/Stop live activity
								Button(action: {
									if activityManager.isActivityActive {
										activityManager.stopActivity()
									} else {
										activityManager.startActivity(
											name: "Account Balance",
											symbol: "USD",
											initialValue: balanceUsd
										)
									}
								}) {
									Image(systemName: activityManager.isActivityActive ? "stop.circle.fill" : "play.circle.fill")
										.foregroundStyle(.tubAccent)
								}
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
        .onChange(of: userModel.portfolioBalanceUsd) { value in
            updateLiveActivity()
        }
    }
}
