//
//  TokenView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import Combine
import SwiftUI
import TubAPI

enum Timespan: String, CaseIterable {
    case live = "LIVE"
    case thirtyMin = "30M"

    var timeframeSecs: Double {
        switch self {
        case .live: return CHART_INTERVAL
        case .thirtyMin: return 30 * 60
        }
    }
}

struct TokenView: View {
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var notificationHandler: NotificationHandler

    @State private var showInfoCard = false
    @State private var selectedTimespan: Timespan = .live
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
        NavigationStack {
            ZStack {
                // Main content
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer().frame(height: 20)
                        tokenInfoView
                        chartView
                            .padding(.top, 5)
                        intervalButtons
                            .padding(.bottom, 12)
                            .padding(.top, 12)
                    }

                    VStack(spacing: 0) {
                        infoCardLowOpacity
                            .opacity(0.8)
                            .padding(.horizontal, 8)
                        ActionButtonsView(
                            tokenModel: tokenModel,
                            showBuySheet: $showBuySheet,
                            handleBuy: handleBuy,
                            onSellSuccess: onSellSuccess
                        )
                        .equatable()
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(AppColors.white)

                infoCardOverlay
                buySheetOverlay
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dismissKeyboardOnTap()
            .background(.black)
            .navigationBarBackButtonHidden(true)
        }
        .background(.black)
    }

    private var tokenInfoView: some View {
        HStack(alignment: .center) {
            // Image column
            if tokenModel.token.imageUri != "" {
                ImageView(imageUri: tokenModel.token.imageUri, size: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Text column
            VStack(alignment: .leading, spacing: 0) {
                Text("$\(tokenModel.token.symbol)")
                    .font(.sfRounded(size: .lg, weight: .semibold)).opacity(0.7)

                HStack(alignment: .center, spacing: 6) {
                    if tokenModel.isReady {
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
                    else {
                        LoadingBox(width: 200, height: 40).padding(.vertical, 4)
                    }
                }

                let price = priceModel.formatPrice(usd: tokenModel.priceChange.amountUsd, showSign: true)
                HStack {

                    if tokenModel.isReady {
                        Text(price)
                        Text("(\(tokenModel.priceChange.percentage, specifier: "%.1f")%)")
                        Text("\(formatDuration(tokenModel.currentTimeframe.timeframeSecs))").foregroundColor(
                            .gray
                        )
                    }
                    else {
                        LoadingBox(width: 160, height: 12)
                    }
                }
                .font(.sfRounded(size: .sm, weight: .semibold))
                .foregroundColor(tokenModel.priceChange.amountUsd >= 0 ? .green : .red)
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
                LoadingBox(height: 350)
            }
            else if selectedTimespan == .live {
                ChartView(
                    prices: tokenModel.prices,
                    timeframeSecs: selectedTimespan.timeframeSecs,
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
        HStack {
            Spacer()
            HStack(spacing: 4) {
                intervalButton(for: .live)
                intervalButton(for: .thirtyMin)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private func intervalButton(for timespan: Timespan) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTimespan = timespan
                tokenModel.updateHistoryInterval(timespan)
            }
        } label: {
            HStack(spacing: 4) {
                if timespan == .live {
                    Circle()
                        .fill(AppColors.red)
                        .frame(width: 7, height: 7)
                }
                Text(timespan.rawValue)
                    .font(.sfRounded(size: .sm, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: 65)
            .background(selectedTimespan == timespan ? AppColors.aquaBlue : Color.clear)
            .foregroundColor(selectedTimespan == timespan ? AppColors.black : AppColors.white)
            .cornerRadius(20)
        }
    }

    /* ------------------------------ Info Overlays ----------------------------- */

    private var stats: [(String, StatValue)] {
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
                            color: gains >= 0 ? AppColors.green : AppColors.red
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
                    VStack(spacing: 2) {
                        HStack(spacing: 0) {
                            Text(stat.0)
                                .font(.sfRounded(size: .xs, weight: .regular))
                                .foregroundColor(AppColors.white.opacity(0.7))
                                .fixedSize(horizontal: true, vertical: false)

                            Text(stat.1.text)
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundColor(stat.1.color ?? AppColors.white)
                                .frame(maxWidth: .infinity, alignment: .topTrailing)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 0.5)
                            .background(AppColors.gray.opacity(0.5))
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Then show remaining stats in two columns
            ForEach(0..<((stats.count - (activeTab == "sell" ? 3 : 0) + 1) / 2), id: \.self) { rowIndex in
                HStack(spacing: 20) {
                    ForEach(0..<2) { columnIndex in
                        let statIndex = (activeTab == "sell" ? 3 : 0) + rowIndex * 2 + columnIndex
                        if statIndex < stats.count {
                            let stat = stats[statIndex]
                            VStack(spacing: 2) {
                                HStack(spacing: 0) {
                                    Text(stat.0)
                                        .font(.sfRounded(size: .xs, weight: .regular))
                                        .foregroundColor(AppColors.white.opacity(0.7))
                                        .fixedSize(horizontal: true, vertical: false)

                                    Text(stat.1.text)
                                        .font(.sfRounded(size: .base, weight: .semibold))
                                        .foregroundColor(AppColors.white)
                                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(height: 0.5)
                                    .background(AppColors.gray.opacity(0.5))
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
        .frame(maxWidth: .infinity, maxHeight: 110, alignment: .topLeading)
        .background(AppColors.darkGrayGradient)
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
                AppColors.black.opacity(0.2)
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
                AppColors.black.opacity(0.4)
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
