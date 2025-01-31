//
//  TokenView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import Combine
import SwiftUI
import TubAPI

/**
 * This view is responsible for displaying a specific token's details and chart.
*/
struct TokenView: View {
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @State private var keyboardHeight: CGFloat = 0
    @State private var showInfoOverlay = false
    
    let animate: Bool
    
    var tokenData: TokenData? {
        return userModel.tokenData[tokenModel.tokenId]
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
                tokenInfoView
                
                chartView
                    .padding(.top, 5)
                
                intervalButtons
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                Spacer()
                TokenInfoPreview(tokenModel: tokenModel, activeTab: activeTab)
                    .opacity(0.8)
                ActionButtonsView(
                    tokenModel: tokenModel
                )
                .equatable()
            }
            .padding(.top, 8)
            .padding(.bottom, 2)
            .padding(.horizontal, 8)
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
                } else {
                    LoadingBox(width: 30, height: 30)
                }
                
                if let symbol = tokenData?.metadata.symbol, symbol != "" {
                    Text("$\(symbol)")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                } else {
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

                    Button(action: {
                        if let tokenData = tokenData, tokenData.liveData != nil {
                            showInfoOverlay.toggle()
                        }
                    }) {
                        Image("Info")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .sheet(isPresented: $showInfoOverlay) {
                        if let tokenData = tokenData, let generalStats = self.generalStats {
                            TokenInfoCardView(
                                tokenData: tokenData,
                                stats: generalStats,
                                sellStats: sellStats
                            )
                            .presentationDetents([.height(400)])
                            .presentationCornerRadius(30)
                        } else {
                            ErrorView(errorMessage: "Couldn't find token information.", retryAction: {})
                                .presentationDetents([.height(400)])
                        }
                    }
                }
                
            } else {
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
                        } else if priceChange < 0 {
                            Image(systemName: "triangle.fill")
                                .resizable()
                                .frame(width: 12, height: 8)
                                .rotationEffect(.degrees(180))
                                .foregroundStyle(.tubError)
                        } else {
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
                } else {
                    LoadingBox(width: 160, height: 14)
                }
            }
            .font(.sfRounded(size: .sm, weight: .semibold))
            .foregroundStyle(
                priceChange > 0 ? .tubSuccess : priceChange < 0 ? .tubError : .tubNeutral
            )
        }
        .padding(.horizontal)
    }
    
    let height = UIScreen.main.bounds.height * 0.4
    
    private var chartView: some View {
        Group {
            if !tokenModel.isReady {
                LoadingBox(height: height)
            } else if tokenModel.selectedTimespan == .live {
                if tokenModel.prices.isEmpty {
                    VStack {
                        Text("No trades found")
                            .font(.sfRounded(size: .base, weight: .semibold))
                            .frame(height: height)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.tubText, lineWidth: 1)
                            )
                    }.frame(minWidth: .infinity, maxHeight: height).padding(2)
                } else {
                    ChartView(
                        rawPrices: tokenModel.prices,
                        purchaseData: tokenModel.purchaseData,
                        animate: animate,
                        height: height
                    )
                }
            } else if tokenModel.candles.count == 0 {
                LoadingBox(height: height)
            } else {
                CandleChartView(
                    candles: tokenModel.candles,
                    animate: animate,
                    timeframeMins: 30,
                    height: height
                )
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
            } else {
                Spacer().frame(height: 32)
            }
        }
    }
    
    private var sellStats: [StatValue]? {
        guard
            let tokenData,
            tokenModel.isReady,
            let priceUsd = tokenModel.prices.last?.priceUsd,
            priceUsd > 0,
            activeTab == .sell
        else {
            return nil
        }
        var stats = [StatValue]()
        
        let decimals = pow(10.0, Double(tokenData.metadata.decimals))
        if let purchaseData = tokenModel.purchaseData {
            let tokenBalance = Double(purchaseData.amountToken) / decimals
            let tokenBalanceUsd = tokenBalance * (tokenModel.prices.last?.priceUsd ?? 0)
            let initialValueUsd = tokenBalance * purchaseData.priceUsd
            let gains = tokenBalanceUsd - initialValueUsd
            let percentageGain = gains / initialValueUsd * 100
            stats.append(
                StatValue(
                    title: "Gains",
                    value: "\(priceModel.formatPrice(usd: gains, showSign: true)) (\(String(format: "%.2f", percentageGain))%)",
                    color: gains >= 0 ? Color.tubSuccess : Color.tubError
                )
            )
        }

        let tokenBalance = Double(balanceToken) / decimals
        let tokenBalanceUsd = tokenBalance * (tokenModel.prices.last?.priceUsd ?? 0)

        stats.append(
            StatValue(
                title: "You own",
                value: "\(priceModel.formatPrice(usd: tokenBalanceUsd, maxDecimals: 2, minDecimals: 2)) (\(formatLargeNumber(tokenBalance)) \(tokenData.metadata.symbol))"
            )
        )
        return stats
    }

    private var generalStats: [StatValue]? {
        if let token = userModel.tokenData[tokenModel.tokenId]
        , let liveData = token.liveData {
            return [
                StatValue(title: "Market Cap", value: priceModel.formatPrice(usd: liveData.priceUsd * (Double(liveData.supply) / pow(10.0, Double(token.metadata.decimals))), formatLarge: true)),
                StatValue(title: "Volume", caption: "30m", value: priceModel.formatPrice(usd: liveData.stats.volumeUsd, formatLarge: true)),
                StatValue(title: "Trades", caption: "30m", value: liveData.stats.trades.formatted()),
                StatValue(title: "Change", caption: "30m", value: String(format: "%.2f%%", liveData.stats.priceChangePct)),
            ]
        }
        return nil
    }
}
