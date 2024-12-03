//
//  TokenInfoCardView.swift
//  Tub
//
//  Created by yixintan on 10/11/24.
//
import SwiftUI

struct TokenInfoCardView: View {
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    var stats: [StatValue]
    var sellStats: [StatValue]?

    init(tokenModel: TokenModel, stats: [StatValue], sellStats: [StatValue]? = nil) {
        self.tokenModel = tokenModel
        self.stats = stats
        self.sellStats = sellStats
    }

    private var statRows: Int { (self.stats.count + 1) / 2 }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 60, height: 3)
                    .background(.tubNeutral)
                    .cornerRadius(100)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .center)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(tokenModel.token.name)
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.bottom, 4)
                    if let sellStats {
                        ForEach(sellStats) { stat in
                            VStack(spacing: 0) {
                                StatView(stat: stat)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    ForEach(0..<statRows, id: \.self) { rowIndex in
                        HStack(spacing: 20) {
                            ForEach(0..<2) { columnIndex in
                                let statIndex = rowIndex * 2 + columnIndex
                                if statIndex < stats.count {
                                    StatView(stat: stats[statIndex])
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("About")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        Text("\(tokenModel.token.description)")
                            .font(.sfRounded(size: .sm, weight: .regular))
                            .foregroundStyle(.tubText)
                            .multilineTextAlignment(.leading)
                            .padding(6)
                    }
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(Gradients.cardBgGradient)
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
        .padding(.vertical, 6)
    }
}

#Preview {
    @Previewable @State var isDarkMode = false
    @Previewable @StateObject var priceModel = {
        let model = SolPriceModel.shared
        spoofPriceModelData(model)
        return model
    }()

    var sellStats: [StatValue] {
        var stats: [StatValue] = []
        stats.append(
            StatValue(
                title: "Gains",
                value:
                    "\(priceModel.formatPrice(usd: 100, showSign: true)) (\(String(format: "%.2f", 5.4))%)",
                color: .tubSuccess
            )
        )

        // Add position stats
        stats.append(
            StatValue(
                title: "You own",
                value:
                    "\(priceModel.formatPrice(usd: 69, maxDecimals: 2, minDecimals: 2)) (\(formatLargeNumber(1e8)) \(tokenModel.token.symbol))"
            )
        )
        return stats
    }

    var generalStats: [StatValue] {
        let ret = [
            StatValue(title: "Market Cap", value: priceModel.formatPrice(usd: 1e9, formatLarge: true)),
            StatValue(title: "Volume (1h)", value: priceModel.formatPrice(usd: 1e8, formatLarge: true)),
            StatValue(title: "Liquidity", value: priceModel.formatPrice(usd: 1e8, formatLarge: true)),
            StatValue(title: "Unique holders", value: formatLargeNumber(1e5)),
        ]
        //        print(ret)
        return ret
    }
    // Create mock token model with sample data
    let tokenModel = {
        let model = TokenModel()
        spoofTokenModelData(model)
        return model
    }()

    VStack {
        VStack {
            PrimaryButton(text: "Toggle Dark Mode") {
                isDarkMode.toggle()
            }
        }
        .frame(maxHeight: 400)
        .padding(16)
        .background(.tubBuySecondary)
        TokenInfoCardView(tokenModel: tokenModel, stats: generalStats, sellStats: sellStats)
            .environmentObject(priceModel)
            .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
