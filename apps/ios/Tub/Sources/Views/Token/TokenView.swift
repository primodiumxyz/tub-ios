//
//  ExploreView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import SwiftUI
import Combine
import TubAPI

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
    
    private var stats: [(String, String)] {
        return tokenModel.getTokenStats(priceModel: priceModel)
    }
    
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
                if activeTab != "sell" {
                    infoCardLowOpacity
                        .opacity(0.5) // Adjust opacity here
                        .padding(.horizontal, 8)
                        .padding(.bottom, -4)
                }
                

                BuySellForm(
                    tokenModel: tokenModel,
                    activeTab: $activeTab,
                    showBuySheet: $showBuySheet,
                    defaultAmount: $defaultAmount,
                    handleBuy: handleBuy
                )
                .equatable() // Add this modifier
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(AppColors.white)
            
            infoCardOverlay
            buySheetOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                }
                Image(systemName: "info.circle.fill")
                    .frame(width: 16, height: 16)
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
                ChartView(prices: tokenModel.prices, timeframeSecs: 120.0, purchaseTime: tokenModel.purchaseTime, purchaseAmount: tokenModel.balanceLamps)
            } else {
                CandleChartView(prices: tokenModel.prices, intervalSecs: 90, timeframeMins: 30)
                    .id(tokenModel.prices.count)
            }
        }
    }
    
    private var intervalButtons: some View {
        HStack {
            Spacer()
            HStack {
                intervalButton(for: .live)
                intervalButton(for: .thirtyMin)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var infoCardLowOpacity: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Stats")
                .font(.sfRounded(size: .xl, weight: .semibold))
                .foregroundColor(AppColors.white)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            TokenStatsGridView(stats: tokenStats)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: 110, alignment: .topLeading)
        .background(AppColors.darkGrayGradient)
        .cornerRadius(12)
        .padding(.top, 16)
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
        Group {
            if showBuySheet {
                AppColors.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            print("CLOSING")
                            showBuySheet = false
                        }
                    }
                
                BuyForm(isVisible: $showBuySheet, defaultAmount: $defaultAmount, tokenModel: tokenModel, onBuy: handleBuy)
                    .transition(.move(edge: .bottom))
                    .offset(y:40)
                    .zIndex(2) // Ensure it stays on top
            }
        }
    }
}

struct LoadingPrice: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.05))
            .frame(width: 120, height: 32)
            .shimmering(opacity: 0.1)
    }
}

struct LoadingPriceChange: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.05))
            .frame(width: 80, height: 20)
            .shimmering(opacity: 0.1)
    }
}

struct LoadingChart: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.03))
            .frame(height: 350)
            .shimmering(opacity: 0.08)
    }
}

struct ShimmeringView: ViewModifier {
    @State private var phase: CGFloat = 0
    let opacity: Double
    
    init(opacity: Double = 0.1) {
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Color.white
                        .opacity(opacity)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * 2)
                                .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                        )
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering(opacity: Double = 0.1) -> some View {
        modifier(ShimmeringView(opacity: opacity))
    }

    private var tokenStats: [(String, String)] {
        var stats = [(String, String)]()
        
        if activeTab == "sell" {
            // Calculate token amount and value
            let tokenAmount = Double(tokenModel.balanceLamps) / pow(10.0, Double(tokenModel.token.decimals ?? 0))
            let currentValueLamps = Int(Double(tokenModel.balanceLamps) / 1e9 * Double(tokenModel.prices.last?.price ?? 0))
            
            // Calculate profit
            let initialValueUsd = priceModel.lamportsToUsd(lamports: tokenModel.amountBoughtLamps)
            let currentValueUsd = priceModel.lamportsToUsd(lamports: currentValueLamps)
            let gains = currentValueUsd - initialValueUsd
            let percentageGain = tokenModel.amountBoughtLamps > 0 ? gains / initialValueUsd * 100 : 0
            
            // Add position stats first
            stats += [
                ("You Own", "\(formatLargeNumber(tokenAmount)) \(tokenModel.token.symbol ?? "")"),
                ("Value", priceModel.formatPrice(lamports: currentValueLamps)),
                // ("All time gains", tokenModel.amountBoughtLamps > 0 ? 
                //     "\(priceModel.formatPrice(usd: gains, showSign: true)) (\(String(format: "%.2f", percentageGain))%)" : "—"),
                // ("", "") // Spacer
            ]
        }
        
        // Add market stats
        stats += [
            ("Market Cap", {
                let price = tokenModel.prices.last?.price ?? 0
                let supply = tokenModel.token.supply ?? 0
                let decimals = tokenModel.token.decimals ?? 0
                return price > 0 ? priceModel.formatPrice(lamports: price * supply / Int(pow(10.0, Double(decimals)))) : "—"
            }()),
            ("Volume (\(String(tokenModel.token.volume?.interval ?? "24h")))", {
                let volume = tokenModel.token.volume?.value ?? 0
                return volume > 0 ? formatLargeNumber(Double(volume) / 1e9) : "—"
            }()),
            ("Holders", "53.3K"),
            ("Supply", {
                let supply = tokenModel.token.supply ?? 0
                let decimals = tokenModel.token.decimals ?? 0
                return supply > 0 ? formatLargeNumber(Double(supply) / pow(10.0, Double(decimals))) : "—"
            }())
        ]
        
        return stats
    }
}

