//
//  TokenInfoPreview.swift
//  Tub
//
//  Created by Henry on 11/27/24.
//

import SwiftUI
import TubAPI

struct TokenInfoPreview: View {
    @EnvironmentObject var userModel: UserModel
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    // add the color scheme
    @Environment(\.colorScheme) var colorScheme

    var activeTab: PurchaseState
    @State private var showInfoOverlay: Bool = false
    
    var tokenData : TokenData? {
        userModel.tokenData[tokenModel.tokenId]
    }
    
    var balanceToken: Int {
        userModel.tokenData[tokenModel.tokenId]?.balanceToken ?? 0
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
        // Calculate current value
        
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
                    value:
                        "\(priceModel.formatPrice(usd: gains, showSign: true)) (\(String(format: "%.2f", percentageGain))%)",
                    color: gains >= 0 ? Color.tubSuccess : Color.tubError
                )
            )
        }

        // Add position stats

        let tokenBalance = Double(balanceToken) / decimals
        let tokenBalanceUsd = tokenBalance * (tokenModel.prices.last?.priceUsd ?? 0)

        stats.append(
            StatValue(
                title: "You own",
                value:
                    "\(priceModel.formatPrice(usd: tokenBalanceUsd, maxDecimals: 2, minDecimals: 2)) (\(formatLargeNumber(tokenBalance)) \(tokenData.metadata.symbol))"
            )
        )
        return stats
    }

    private var generalStats: [StatValue]? {
        if let token = userModel.tokenData[tokenModel.tokenId]
        , let liveData = token.liveData {
            return [
                // todo: readd when quicknode fixes this value
//                StatValue(title: "Market Cap", value: priceModel.formatPrice(usd: liveData.marketCapUsd, formatLarge: true)),
                StatValue(title: "Change", caption: HOT_TOKENS_INTERVAL, value: String(format: "%.2f%%", liveData.stats.priceChangePct)),
                StatValue(title: "Volume", caption: HOT_TOKENS_INTERVAL, value: priceModel.formatPrice(usd: liveData.stats.volumeUsd, formatLarge: true)),
                StatValue(title: "Trades", caption: HOT_TOKENS_INTERVAL, value: liveData.stats.trades.formatted()),
            ]
        }
        return nil
    }

    private var statRows: Int { if let generalStats { (generalStats.count + 1) / 2 } else { 0 } }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                if generalStats == nil {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: 70)
                        .padding(18)
                }
                else if let sellStats, activeTab == .sell {
                    ForEach(sellStats) { stat in
                        VStack(spacing: 0) {
                            StatView(stat: stat)
                        }
                        .padding(.vertical, 4)
                    }
                }
                else if let generalStats {
                    ForEach(0..<statRows, id: \.self) { rowIndex in
                        HStack(spacing: 20) {
                            ForEach(0..<2) { columnIndex in
                                let statIndex = rowIndex * 2 + columnIndex
                                if statIndex < generalStats.count {
                                    StatView(stat: generalStats[statIndex])
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 70)
            .padding(18)
            .background(colorScheme == .dark ? Gradients.grayGradient : Gradients.clearGradient)
            .overlay(
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: 30,
                        bottomLeading: 0,
                        bottomTrailing: 0,
                        topTrailing: 30
                    )
                )
                .inset(by: 1)
                .stroke(colorScheme == .dark ? .clear : .tubBuySecondary, lineWidth: 1)
                .padding(.bottom, -10)
            )
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: 30,
                        bottomLeading: 0,
                        bottomTrailing: 0,
                        topTrailing: 30
                    )
                )
            )

            Rectangle()
                .fill(colorScheme == .dark ? .clear : .white)
                .frame(maxWidth: .infinity, maxHeight: 8)
                .padding(.bottom, -4)
        }
        .onTapGesture {
            if generalStats == nil {
                return
            }
            self.showInfoOverlay.toggle()
        }
        .sheet(isPresented: $showInfoOverlay) {
                if let tokenData, let generalStats {
                    TokenInfoCardView(tokenData: tokenData, stats: generalStats, sellStats: sellStats)
                        .presentationDetents([.height(400)])
                } else {
                    ErrorView(errorMessage: "Couldn't find token information.", retryAction: {})
                        .presentationDetents([.height(400)])
                }
        }
    }
}

private struct StatView: View {
    var stat: StatValue

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Text(stat.title)
                    .font(.sfRounded(size: .sm, weight: .regular))
                    .foregroundStyle(.tubText)
                    .fixedSize(horizontal: true, vertical: false)
                
                if let caption = stat.caption {
                    Text(caption)
                        .font(.sfRounded(size: .xxs, weight: .regular))
                        .foregroundStyle(.tubText.opacity(0.7))
                }

                Text(stat.value)
                    .font(.sfRounded(size: .base, weight: .semibold))
                    .foregroundStyle(stat.color ?? .primary)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }

            Rectangle()
                .fill(.tubText)
                .opacity(0.5)
                .frame(maxWidth: .infinity, maxHeight: 1)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    @Previewable @State var isDark = false

    @Previewable @StateObject var userModel = UserModel.shared
    @Previewable @StateObject var priceModel = {
        let model = SolPriceModel.shared
        spoofPriceModelData(model)
        return model
    }()

    var activeTab: PurchaseState {
        return balanceToken > 0 ? .sell : .buy
    }

    // Create mock token model with sample data
    let tokenModel = {
        let model = TokenModel()
        spoofTokenModelData(userModel: userModel, tokenModel: model)
        return model
    }()

    var balanceToken : Int {
       userModel.tokenData[tokenModel.tokenId]?.balanceToken ?? 0
    }
    
    VStack {
        VStack {
            Text("Modifiers")
            PrimaryButton(text: "Toggle Buy/Sell") {
                Task{
                    if balanceToken > 0 {
                        await userModel.updateTokenData(mint: tokenModel.tokenId, balance: 0)
                        tokenModel.purchaseData = nil
                    }
                    else {
                        await userModel.updateTokenData(mint: tokenModel.tokenId, balance: 100)
                        tokenModel.purchaseData = PurchaseData(
                            tokenId: tokenModel.tokenId,
                            timestamp: Date().addingTimeInterval(-60 * 60),
                            amountToken: Int(1e9),
                            priceUsd: 1
                        )
                    }
                }
            }
            PrimaryButton(text: "Toggle Dark Mode") {
                isDark.toggle()
            }
        }.padding(16).background(.tubBuySecondary)
        Spacer().frame(height: 50)

        TokenInfoPreview(tokenModel: tokenModel, activeTab: activeTab)
            .padding(8)
            .border(.red)
            .environmentObject(userModel)
            .environmentObject(priceModel)
            .preferredColorScheme(isDark ? .dark : .light)
    }
}
