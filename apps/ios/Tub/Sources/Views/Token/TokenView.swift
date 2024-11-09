//
//  ExploreView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import SwiftUI
import Combine
import TubAPI

enum TubError: LocalizedError {
    case insufficientBalance
    
    var errorDescription: String? {
        switch self {
        case .insufficientBalance:
            return "Insufficient Balance"
        }
    }
}

struct TokenView : View {
    @EnvironmentObject private var errorHandler: ErrorHandler
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @Binding var activeTab: String
    
    @State private var showInfoCard = false
    @State private var selectedTimespan: Timespan = .live
    @State private var showBuySheet: Bool = false
    @State private var defaultAmount: Double = 50.0
    @State private var keyboardHeight: CGFloat = 0
    
    
    enum Timespan: String, CaseIterable {
        case live = "LIVE"
        case thirtyMin = "30M"
        
        var interval: Interval {
            switch self {
            case .live: return CHART_INTERVAL
            case .thirtyMin: return "30m"
            }
        }
    }
    
    init(tokenModel: TokenModel, activeTab: Binding<String>) {
        self.tokenModel = tokenModel
        self._activeTab = activeTab
    }
    
    func handleBuy(amount: Double) {
        let buyAmountLamps = priceModel.usdToLamports(usd: amount)
        if(buyAmountLamps > userModel.balanceLamps) {
            errorHandler.show(TubError.insufficientBalance)
            return
        }
        tokenModel.buyTokens(buyAmountLamps: buyAmountLamps) { result in
            switch result {
            case .success:
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBuySheet = false
                    activeTab = "sell" //  Switch tab after successful buy
                }
            case .failure(let error):
                print("failed to buy")
                print(error)
                errorHandler.show(error)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                tokenInfoView
                chartView
                intervalButtons
                    .padding(.bottom,8)
                infoCardLowOpacity
                    .opacity(0.8)
                    .padding(.horizontal, 8)
                    .padding(.bottom, -4)
                BuySellForm(
                    tokenModel: tokenModel,
                    activeTab: $activeTab,
                    showBuySheet: $showBuySheet,
                    defaultAmount: $defaultAmount,
                    handleBuy: handleBuy
                )
                .equatable()
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(AppColors.white)
            
            infoCardOverlay
            buySheetOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dismissKeyboardOnTap()
    }
    
    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if tokenModel.token.imageUri != "" {
                    ImageView(imageUri: tokenModel.token.imageUri, size: 20)
                }
                Text("$\(tokenModel.token.symbol)")
                    .font(.sfRounded(size: .lg, weight: .semibold))
            }
            HStack(alignment: .center, spacing: 6) {
                if tokenModel.loading {
                    LoadingPrice()
                } else {
                    Text(priceModel.formatPrice(lamports: tokenModel.prices.last?.price ?? 0, maxDecimals: 9, minDecimals: 2))
                        .font(.sfRounded(size: .xl4, weight: .bold))
                    Image(systemName: "info.circle.fill")
                        .frame(width: 16, height: 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if tokenModel.loading {
                LoadingPriceChange()
            } else {
                HStack {
                    Text(priceModel.formatPrice(lamports: tokenModel.priceChange.amountLamps, showSign: true))
                    Text("(\(tokenModel.priceChange.percentage, specifier: "%.1f")%)")
                    
                    Text(tokenModel.interval).foregroundColor(.gray)
                }
                .font(.sfRounded(size: .sm, weight: .semibold))
                .foregroundColor(tokenModel.priceChange.amountLamps >= 0 ? .green : .red)
            }
        }
        .padding(.horizontal)
        .onTapGesture {
            // Toggle the info card
            withAnimation(.easeInOut) {
                showInfoCard.toggle()
            }
        }
    }
    
    private var chartView: some View {
        Group {
            if tokenModel.loading {
                LoadingChart()
            } else if selectedTimespan == .live {
                ChartView(prices: tokenModel.prices, timeframeSecs: 120.0, purchaseData: tokenModel.purchaseData)
            } else {
                CandleChartView(prices: tokenModel.prices, intervalSecs: 90, timeframeMins: 30)
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
            withAnimation {
                selectedTimespan = timespan
                tokenModel.updateHistoryInterval(timespan.interval)
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
        
        if let purchaseData = tokenModel.purchaseData, activeTab == "sell" {
            // Calculate current value in lamports
            let currentValueLamps = Int(Double(tokenModel.balanceLamps) / 1e9 * Double(tokenModel.prices.last?.price ?? 0))
            
            // Calculate profit
            let initialValueUsd = priceModel.lamportsToUsd(lamports: purchaseData.amount)
            let currentValueUsd = priceModel.lamportsToUsd(lamports: currentValueLamps)
            let gains = currentValueUsd - initialValueUsd
            
            
            
            if purchaseData.amount > 0 {
                let percentageGain = gains / initialValueUsd * 100
                stats += [
                    ("Gains", StatValue(
                        text: "\(priceModel.formatPrice(usd: gains, showSign: true)) (\(String(format: "%.2f", percentageGain))%)",
                        color: gains >= 0 ? AppColors.green : AppColors.red
                    ))
                ]
            }
            
            // Add position stats
            stats += [
                ("You Own", StatValue(
                    text: "\(priceModel.formatPrice(lamports: currentValueLamps, maxDecimals: 2, minDecimals: 2)) (\(priceModel.formatPrice(lamports: tokenModel.balanceLamps, showUnit: false)) \(tokenModel.token.symbol))",
                    color: nil
                ))
            ]
        } else {
            stats += tokenModel.getTokenStats(priceModel: priceModel).map {
                ($0.0, StatValue(text: $0.1, color: nil))
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
                            showInfoCard = false // Close the card
                        }
                    }
                VStack {
                    Spacer()
                    TokenInfoCardView(tokenModel: tokenModel, isVisible: $showInfoCard, activeTab: $activeTab)
                }
                .transition(.move(edge: .bottom))
                .zIndex(1) // Ensure it stays on top
            }
        }
    }
    
    
    private var buySheetOverlay: some View {
            guard showBuySheet else {
             return   AnyView(EmptyView())
            }
        return AnyView (
            Group {
                AppColors.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showBuySheet = false
                        }
                    }
                
                BuyForm(isVisible: $showBuySheet, defaultAmount: $defaultAmount, tokenModel: tokenModel, onBuy: handleBuy)
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
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.16)) {
                    self.keyboardHeight = keyboardFrame.height / 2
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation(.easeOut(duration: 0.16)) {
                self.keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}
