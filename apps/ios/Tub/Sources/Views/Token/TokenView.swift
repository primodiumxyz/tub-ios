//
//  TokenView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import Combine
import SwiftUI
import TubAPI

struct TokenView: View {
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var notificationHandler: NotificationHandler

	@State private var showInfoCard = false
	@State private var keyboardHeight: CGFloat = 0

	let animate: Bool
	
    var tokenData : TokenData? {
        userModel.tokenData[tokenModel.tokenId]
    }
    
    var balanceToken: Int {
        tokenData?.balanceToken ?? 0
    }
    
    var activeTab: PurchaseState {
        return balanceToken > 0 ? PurchaseState.sell : PurchaseState.buy
    }

    init(
        tokenModel: TokenModel,
		animate: Bool = false
    ) {
        self.tokenModel = tokenModel
		self.animate = animate
    }


    var body: some View {
        ZStack {
            // Main content
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Spacer().frame(height: 20)
                    tokenInfoView

                    chartView
                        .padding(.top, 5)

					intervalButtons
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                }

                VStack(spacing: 0) {
                    TokenInfoPreview(tokenModel: tokenModel, activeTab: activeTab)
                        .opacity(0.8)
                    ActionButtonsView(
                        tokenModel: tokenModel
                    )
                    .equatable()
                }.padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.primary)
        }
        .dismissKeyboardOnTap()
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                if let image = tokenData?.metadata.imageUri, image != "" {
                    ImageView(imageUri: image, size: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                else {
                    LoadingBox(width: 30, height: 30)
                }

                if let symbol = tokenData?.metadata.symbol, symbol != "" {
                    Text("$\(symbol)")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                }
                else {
                    LoadingBox(width: 100, height: 20)
                }
            }

            if tokenModel.isReady {
                HStack(alignment: .center, spacing: 6) {
                    let price = priceModel.formatPrice(
                        usd: tokenModel.prices.last?.priceUsd ?? 0,
                        maxDecimals: 9,
                        minDecimals: 2
                    )
                    Text(price)
                        .font(.sfRounded(size: .xl4, weight: .bold))
                    Image(systemName: "info.circle.fill")
                        .frame(width: 16, height: 16)
                }

            }
            else {
                LoadingBox(width: 200, height: 40).padding(.vertical, 4)
            }

            let priceChange = tokenModel.priceChange.amountUsd
            let priceChangePercentage = tokenModel.priceChange.percentage
            HStack(alignment: .center, spacing: 0) {
                if tokenModel.isReady {
                    // Price change indicator
                    HStack(spacing: 4) {
                        if priceChange > 0 {
                            Image(systemName: "triangle.fill")
                                .resizable()
                                .frame(width: 12, height: 8)
                                .foregroundStyle(.tubSuccess)
                        }
                        else if priceChange < 0 {
                            Image(systemName: "triangle.fill")
                                .resizable()
                                .frame(width: 12, height: 8)
                                .rotationEffect(.degrees(180))
                                .foregroundStyle(.tubError)
                        }
                        else {
                            Image(systemName: "rectangle.fill")
                                .resizable()
                                .frame(width: 8, height: 3)
                                .foregroundStyle(.tubNeutral)
                        }

                        Text(
                            "\(abs(priceChangePercentage), specifier: abs(priceChangePercentage) < 10 ? "%.2f" : "%.1f")%"
                        )
                        .font(.sfRounded(size: .base, weight: .semibold))
                    }
                    .frame(maxWidth: 75, alignment: .leading)
                    Text("\(formatDuration(tokenModel.selectedTimespan.seconds))").foregroundStyle(.gray)
                }
                else {
                    LoadingBox(width: 160, height: 14)
                }
            }
            .font(.sfRounded(size: .sm, weight: .semibold))
            .foregroundStyle(
                priceChange > 0 ? .tubSuccess : priceChange < 0 ? .tubError : .tubNeutral
            )
        }
        .padding(.horizontal)
        .onTapGesture {
            withAnimation(.easeInOut) {
                showInfoCard.toggle()
            }
        }
    }

    let height = UIScreen.main.bounds.height * 0.38

    private var chartView: some View {
        Group {
            if !tokenModel.isReady {
                LoadingBox(height: height)
            } else if tokenModel.prices.isEmpty {
                Text("No trades found").font(.sfRounded(size: .base, weight: .semibold)).frame(height: height)
                
            } else if tokenModel.selectedTimespan == .live {
                ChartView(
                    rawPrices: tokenModel.prices,
                    purchaseData: tokenModel.purchaseData,
                    animate: animate,
                    height: height
                )
                //				.id(tokenModel.prices.count) // results in odd behavior: toggles between prices.count = 0 and prices.count = correct value
            }
            else {
                CandleChartView(
                    candles: tokenModel.candles,
                    animate: animate,
                    timeframeMins: 30,
                    height: height
                )
                .id(tokenModel.prices.count)  // should be tokenModel.candles.count?
            }
        }
    }

    /* ---------------------------- Interval Buttons ---------------------------- */

    private var intervalButtons: some View {
        Group {
            if tokenModel.isReady {
                HStack {
                    Spacer()
                    IntervalButton(
                        timespan: .live,
                        isSelected: tokenModel.selectedTimespan == .live,
                        action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                tokenModel.selectedTimespan = .live
                            }
                        }
                    )
                    IntervalButton(
                        timespan: .candles,
                        isSelected: tokenModel.selectedTimespan == .candles,
                        action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                tokenModel.selectedTimespan = .candles
                            }
                        }
                    )
                    Spacer()
                }
                .frame(height: 32)
                .padding(.horizontal)
            }
            else {
                Spacer().frame(height: 32)
            }
        }
    }
}
