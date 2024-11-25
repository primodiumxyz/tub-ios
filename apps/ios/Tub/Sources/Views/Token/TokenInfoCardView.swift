//
//  TokenInfoCardView.swift
//  Tub
//
//  Created by yixintan on 10/11/24.
//
import SwiftUI

struct TokenInfoCardView: View {
    @ObservedObject var tokenModel: TokenModel
    @Binding var isVisible: Bool
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var userModel: UserModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var dragOffset: CGFloat = 0.0
    @State private var animatingSwipe: Bool = false
    @State private var isClosing: Bool = false

    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }

    private struct StatValue {
        let text: String
        let color: Color?
    }

    private var stats: [(String, StatValue)] {
        var stats = [(String, StatValue)]()

        if let purchaseData = userModel.purchaseData, activeTab == "sell" {
            // Calculate current value
            let tokenBalance = Double(userModel.tokenBalanceLamps ?? 0) / 1e9
            let tokenBalanceUsd = tokenBalance * (tokenModel.prices.last?.priceUsd ?? 0)
            let initialValueUsd = priceModel.lamportsToUsd(lamports: purchaseData.amount)

            // Calculate profit
            let gains = tokenBalanceUsd - initialValueUsd

            if initialValueUsd > 0 {
                let percentageGain = gains / initialValueUsd * 100
                stats += [
                    (
                        "Gains",
                        StatValue(
                            text:
                                "\(priceModel.formatPrice(usd: gains, showSign: true)) (\(String(format: "%.2f", percentageGain))%)",
                            color: gains >= 0 ? Color.green : Color.red
                        )
                    )
                ]
            }

            stats += [
                (
                    "You own",
                    StatValue(
                        text:
                            "\(priceModel.formatPrice(usd: tokenBalanceUsd, maxDecimals: 2, minDecimals: 2)) (\(formatLargeNumber(tokenBalance)) \(tokenModel.token.symbol))",
                        color: nil
                    )
                )
            ]

        }

        // Add original stats from tokenModel
        stats += tokenModel.getTokenStats(priceModel: priceModel).map {
            ($0.0, StatValue(text: $0.1 ?? "", color: nil))
        }

        return stats
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 60, height: 3)
                    .background(Color("grayLight"))
                    .cornerRadius(100)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .center)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Stats")
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.bottom, 4)

                    ForEach(stats, id: \.0) { stat in
                        VStack(spacing: 10) {
                            HStack(alignment: .center) {
                                Text(stat.0)
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundStyle(Color.secondary)
                                    .fixedSize(horizontal: true, vertical: false)

                                Text(stat.1.text)
                                    .font(.sfRounded(size: .base, weight: .semibold))
                                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                                    .foregroundStyle(stat.1.color ?? Color.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            //divider
                            Rectangle()
                                .foregroundStyle(Color.clear)
                                .frame(height: 0.5)
                                .background(Color.gray.opacity(0.5))
                        }
                        .padding(.vertical, 6)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("About")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        Text("\(tokenModel.token.description)")
                            .font(.sfRounded(size: .sm, weight: .regular))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(colorScheme == .dark ? AppColors.darkGrayGradient : AppColors.lightGrayGradient)
                .cornerRadius(20)
            }
        }
        .padding(.vertical, 0)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.44, alignment: .topLeading)
        .background(Color(UIColor.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 0.5)
                .stroke(colorScheme == .dark ? Color("grayShadow") : Color.primary, lineWidth: 1)
        )
        .transition(.move(edge: .bottom))
        .offset(y: dragOffset)
        .ignoresSafeArea(edges: .horizontal)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    let verticalAmount = value.translation.height

                    if verticalAmount > threshold && !animatingSwipe {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            dragOffset = UIScreen.main.bounds.height
                        }
                        animatingSwipe = true
                        isClosing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            isVisible = false  // Close the card
                        }
                    }
                    else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                // Reset when becoming visible
                isClosing = false
                dragOffset = 0
                animatingSwipe = false
            }
            else if !isClosing {
                // Only animate closing if not already closing from gesture
                withAnimation(.easeInOut(duration: 0.4)) {
                    dragOffset = UIScreen.main.bounds.height
                }
            }
        }
        .transition(.move(edge: .bottom))
    }
}
