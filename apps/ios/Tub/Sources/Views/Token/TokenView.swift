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
    @Environment(\.colorScheme) private var colorScheme

    @State private var showInfoCard = false
    @State private var showBuySheet: Bool = false
    @State private var keyboardHeight: CGFloat = 0

    var onSellSuccess: (() -> Void)?

    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }

    init(tokenModel: TokenModel, onSellSuccess: (() -> Void)? = nil) {
        self.tokenModel = tokenModel
        self.onSellSuccess = onSellSuccess
    }

    func handleBuy(amountUsd: Double) async {
        guard let priceUsd = tokenModel.prices.last?.priceUsd
        else {
            notificationHandler.show(
                "Something went wrong. Please try again.",
                type: .error
            )
            return
        }

        let buyAmountLamps = priceModel.usdToLamports(usd: amountUsd)

        let priceLamps = priceModel.usdToLamports(usd: priceUsd)

        do {
            try await userModel.buyTokens(
                buyAmountLamps: buyAmountLamps,
                priceLamps: priceLamps,
                priceUsd: priceUsd
            )
            await MainActor.run {
                showBuySheet = false
                notificationHandler.show(
                    "Successfully bought tokens!",
                    type: .success
                )
            }
        }
        catch {
            notificationHandler.show(
                error.localizedDescription,
                type: .error
            )
        }
    }

    var body: some View {
        ZStack {
            // Main content
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Spacer().frame(height: 60)
                    tokenInfoView
                    chartView
                        .padding(.top, 12)
                    intervalButtons
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color.primary)

                VStack(spacing: 0) {
                    infoCardLowOpacity
                        .opacity(0.8)
                    ActionButtonsView(
                        tokenModel: tokenModel,
                        showBuySheet: $showBuySheet,
                        handleBuy: handleBuy,
                        onSellSuccess: onSellSuccess
                    )
                    .equatable()
                }.padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .dismissKeyboardOnTap()
            .background(Color(UIColor.systemBackground))
            .navigationBarBackButtonHidden(true)
            
            // Add these overlays
            infoCardOverlay
            buySheetOverlay
        }
        .background(Color(UIColor.systemBackground))
    }

    private var tokenInfoView: some View {
        HStack(alignment: .center) {
            // Image column
            if tokenModel.token.imageUri != "" {
                ImageView(imageUri: tokenModel.token.imageUri, size: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            else {
                LoadingBox(width: 50, height: 50)
            }

            // Text column
            VStack(alignment: .leading, spacing: 0) {
                if tokenModel.token.symbol != "" {
                    Text("$\(tokenModel.token.symbol)")
                        .font(.sfRounded(size: .lg, weight: .semibold)).opacity(0.7)
                }
                else {
                    LoadingBox(width: 100, height: 20)
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

                let price = priceModel.formatPrice(
                    usd: tokenModel.priceChange.amountUsd,
                    showSign: true,
                    maxDecimals: 9,
                    minDecimals: 2
                )

                HStack {

                    if tokenModel.isReady {
                        Text(price)
                        Text("(\(tokenModel.priceChange.percentage, specifier: "%.1f")%)")
                        Text("\(formatDuration(tokenModel.selectedTimespan.seconds))").foregroundColor(.gray)
                    }
                    else {
                        LoadingBox(width: 160, height: 12)
                    }
                }
                .font(.sfRounded(size: .sm, weight: .semibold))
                .foregroundStyle(tokenModel.priceChange.amountUsd >= 0 ? Color.green : Color.red)
            }
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
            }
            else if tokenModel.selectedTimespan == .live {
                ChartView(
                    prices: tokenModel.prices,
                    height: height
                )
            }
            else {
                CandleChartView(
                    candles: tokenModel.candles,
                    timeframeMins: 30,
                    height: height
                )
                .id(tokenModel.prices.count)
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

    /* ------------------------------ Info Overlays ----------------------------- */

    private var stats: [(String, StatValue)] {
        if !tokenModel.isReady {
            return []
        }
        var stats = [(String, StatValue)]()

        if let purchaseData = userModel.purchaseData, let priceUsd = tokenModel.prices.last?.priceUsd,
            priceUsd > 0,
            activeTab == "sell"
        {
            // Calculate current value
            let tokenBalance = Double(userModel.tokenBalanceLamps ?? 0) / 1e9
            let tokenBalanceUsd = tokenBalance * (tokenModel.prices.last?.priceUsd ?? 0)
            let initialValueUsd = priceModel.lamportsToUsd(lamports: purchaseData.amount)

            // Calculate profit
            let gains = tokenBalanceUsd - initialValueUsd

            if purchaseData.amount > 0, initialValueUsd > 0 {
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

            // Add position stats
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
        else {
            stats += tokenModel.getTokenStats(priceModel: priceModel).map {
                ($0.0, StatValue(text: $0.1 ?? "", color: nil))
            }
        }
        return stats
    }

    private var infoCardLowOpacity: some View {
        VStack(alignment: .leading, spacing: 0) {
            if activeTab == "sell" {
                ForEach(stats.prefix(3), id: \.0) { stat in
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Text(stat.0)
                                .font(.sfRounded(size: .xs, weight: .regular))
                                .foregroundStyle(Color.primary.opacity(0.7))
                                .fixedSize(horizontal: true, vertical: false)

                            Text(stat.1.text)
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundStyle(stat.1.color ?? Color.primary)
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

            // Then show remaining stats in two columns
            ForEach(0..<(stats.count + 1) / 2, id: \.self) { rowIndex in
                HStack(spacing: 20) {
                    ForEach(0..<2) { columnIndex in
                        let statIndex = (activeTab == "sell" ? 3 : 0) + rowIndex * 2 + columnIndex
                        if statIndex < stats.count {
                            let stat = stats[statIndex]
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    Text(stat.0)
                                        .font(.sfRounded(size: .xs, weight: .regular))
                                        .foregroundStyle(Color.primary.opacity(0.7))
                                        .fixedSize(horizontal: true, vertical: false)

                                    Text(stat.1.text)
                                        .font(.sfRounded(size: .base, weight: .semibold))
                                        .foregroundStyle(Color.primary)
                                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Rectangle()
                                    .foregroundStyle(Color.clear)
                                    .frame(height: 0.5)
                                    .background(Color.gray.opacity(0.5))
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: 100, alignment: .topLeading)
        .background(colorScheme == .dark ? AppColors.darkGrayGradient : AppColors.lightGrayGradient)
        .cornerRadius(16)
        .onTapGesture {
            withAnimation(.easeInOut) {
                showInfoCard.toggle()
            }
        }
    }

    private var infoCardOverlay: some View {
        Group {
            if showInfoCard {
                // Fullscreen tap dismiss
                Color(UIColor.systemBackground).opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            showInfoCard = false  // Close the card
                        }
                    }
                VStack {
                    Spacer()
                    TokenInfoCardView(tokenModel: tokenModel, isVisible: $showInfoCard)
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)  // Ensure it stays on top
            }
        }
    }

    private var buySheetOverlay: some View {
        guard showBuySheet else {
            return AnyView(EmptyView())
        }
        return AnyView(
            Group {
                Color(UIColor.systemBackground).opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showBuySheet = false
                        }
                    }

                BuyForm(isVisible: $showBuySheet, tokenModel: tokenModel, onBuy: handleBuy)
                    .transition(.move(edge: .bottom))
                    .offset(y: -keyboardHeight)
                    .zIndex(2)
                    .onAppear {
                        setupKeyboardNotifications()
                    }
                    .onDisappear {
                        removeKeyboardNotifications()
                    }
            }
        )
    }

    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                as? CGRect
            {
                withAnimation(.easeOut(duration: 0.16)) {
                    self.keyboardHeight = keyboardFrame.height / 2
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.16)) {
                self.keyboardHeight = 0
            }
        }
    }

    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}
