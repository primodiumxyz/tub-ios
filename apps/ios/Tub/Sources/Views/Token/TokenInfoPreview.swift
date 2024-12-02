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

    var activeTab: String
    @State private var showInfoOverlay: Bool = false

    private var sellStats: [StatValue]? {
        guard
            tokenModel.isReady,
            let purchaseData = userModel.purchaseData,
            let priceUsd = tokenModel.prices.last?.priceUsd,
            priceUsd > 0,
            activeTab == "sell"
        else {
            return nil
        }
        var stats = [StatValue]()
        // Calculate current value
        let tokenBalance = Double(userModel.tokenBalanceLamps ?? 0) / 1e9
        let tokenBalanceUsd = tokenBalance * (tokenModel.prices.last?.priceUsd ?? 0)
        let initialValueUsd = priceModel.lamportsToUsd(lamports: purchaseData.amount)

        // Calculate profit
        let gains = tokenBalanceUsd - initialValueUsd

        if purchaseData.amount > 0, initialValueUsd > 0 {
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
        stats.append(
            StatValue(
                title: "You own",
                value:
                    "\(priceModel.formatPrice(usd: tokenBalanceUsd, maxDecimals: 2, minDecimals: 2)) (\(formatLargeNumber(tokenBalance)) \(tokenModel.token.symbol))"
            )
        )
        return stats
    }

    private var generalStats: [StatValue] {
        let token = tokenModel.token
        //        print(token)
        let ret = [
            StatValue(title: "Market Cap", value: priceModel.formatPrice(usd: token.marketCapUsd, formatLarge: true)),
            StatValue(title: "Volume (1h)", value: priceModel.formatPrice(usd: token.volumeUsd, formatLarge: true)),
            StatValue(title: "Liquidity", value: priceModel.formatPrice(usd: token.liquidityUsd, formatLarge: true)),
            StatValue(title: "Unique holders", value: formatLargeNumber(Double(token.uniqueHolders))),
        ]
        //        print(ret)
        return ret
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                if let sellStats, activeTab == "sell" {
                    ForEach(sellStats) { stat in
                        VStack(spacing: 0) {
                            StatView(stat: stat)
                        }
                        .padding(.vertical, 4)
                    }
                }
                else {
                    ForEach(0..<(generalStats.count + 1) / 2, id: \.self) { rowIndex in
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
            .padding(24)
            .background(colorScheme == .dark ? Gradients.darkGrayGradient : Gradients.clearGradient)
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
        .frame(maxHeight: 100)
        .onTapGesture {
            self.showInfoOverlay.toggle()
        }
        .sheet(isPresented: $showInfoOverlay) {
            TokenInfoCardView(tokenModel: tokenModel, stats: generalStats)
                .presentationDetents([.height(400)])
        }
    }
}

private struct StatView: View {
    var stat: StatValue

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                Text(stat.title)
                    .font(.sfRounded(size: .xs, weight: .regular))
                    .foregroundStyle(.tubText)
                    .fixedSize(horizontal: true, vertical: false)

                Text(stat.value)
                    .font(.sfRounded(size: .sm, weight: .semibold))
                    .foregroundStyle(stat.color ?? .primary)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
            }

            Divider().padding(.top, 2)
                .frame(height: 0.5)
                .overlay(Color.tubText)
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

    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }

    // Create mock token model with sample data
    let tokenModel = {
        let model = TokenModel()
        spoofTokenModelData(model)
        return model
    }()

    VStack {
        VStack {
            Text("Modifiers")
            PrimaryButton(text: "Toggle Buy/Sell") {
                if userModel.tokenBalanceLamps ?? 0 > 0 {
                    userModel.tokenBalanceLamps = 0
                    userModel.purchaseData = nil
                }
                else {
                    userModel.tokenBalanceLamps = 100
                    userModel.purchaseData = PurchaseData(
                        timestamp: Date().addingTimeInterval(-60 * 60),
                        amount: 1000,
                        price: 100
                    )
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
