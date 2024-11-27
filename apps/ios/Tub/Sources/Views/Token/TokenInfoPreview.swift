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
                    color: gains >= 0 ? Color.green : Color.red
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
        VStack(alignment: .leading, spacing: 0) {
            if let sellStats, activeTab == "sell" {
                ForEach(sellStats) { stat in
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Text(stat.title)
                                .font(.sfRounded(size: .xs, weight: .regular))
                                .foregroundStyle(.primary.opacity(0.7))
                                .fixedSize(horizontal: true, vertical: false)

                            Text(stat.value)
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundStyle(stat.color ?? .tubText)
                                .frame(maxWidth: .infinity, alignment: .topTrailing)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Rectangle()
                            .foregroundStyle(Color.clear)
                            .frame(height: 0.5)
                            .background(Color.gray.opacity(0.5))
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 4)
                }
            }
            else {
                ForEach(0..<(generalStats.count + 1) / 2, id: \.self) { rowIndex in
                    HStack(spacing: 20) {
                        ForEach(0..<2) { columnIndex in
                            let statIndex = (activeTab == "sell" ? 3 : 0) + rowIndex * 2 + columnIndex
                            if statIndex < generalStats.count {
                                let stat = generalStats[statIndex]
                                VStack(spacing: 0) {
                                    HStack(spacing: 0) {
                                        Text(stat.title)
                                            .font(.sfRounded(size: .xs, weight: .regular))
                                            .foregroundStyle(.primary.opacity(0.7))
                                            .fixedSize(horizontal: true, vertical: false)

                                        Text(stat.value)
                                            .font(.sfRounded(size: .base, weight: .semibold))
                                            .foregroundStyle(.primary)
                                            .frame(maxWidth: .infinity, alignment: .topTrailing)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .border(.red)
        .frame(maxWidth: .infinity, maxHeight: 80, alignment: .topLeading)
        .cornerRadius(16)
        .onTapGesture {
            self.showInfoOverlay.toggle()
        }
        .sheet(isPresented: $showInfoOverlay) {
            TokenInfoCardView(tokenModel: tokenModel, stats: generalStats)
                .presentationDetents([.height(300)])
        }
    }
}

#Preview {
    @Previewable @State var activeTab = "sell"
    @Previewable @State var isDark = true

    @Previewable @StateObject var userModel = UserModel.shared
    @Previewable @StateObject var priceModel = {
        let model = SolPriceModel.shared
        spoofPriceModelData(model)
        return model
    }()

    // Create mock token model with sample data
    let tokenModel = TokenModel().apply { model in
        spoofTokenModelData(model)
    }

    VStack {
        VStack {
            Text("Modifiers")
            PrimaryButton(text: "Toggle Buy/Sell") {
                activeTab = activeTab == "sell" ? "buy" : "sell"
            }
            PrimaryButton(text: "Toggle Dark Mode") {
                isDark.toggle()
            }
        }.padding(16).background(.tubBuySecondary)
        Spacer().frame(height: 50)

        TokenInfoPreview(tokenModel: tokenModel, activeTab: activeTab)
            .environmentObject(userModel)
            .environmentObject(priceModel)
            .preferredColorScheme(isDark ? .dark : .light)
    }
}

// Helper extension to make initialization cleaner
extension TokenModel {
    func apply(_ closure: (TokenModel) -> Void) -> TokenModel {
        closure(self)
        return self
    }
}
