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
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @Binding var activeTab: String
    
    @State private var showInfoCard = false
    @State private var selectedTimespan: Timespan = .live
    @State private var showBuySheet: Bool = false
    @State private var defaultAmount: Double = 50.0
    
    // TODO: have the token info card in one place and adapt params for opacity (open/close)
    private var stats: [(String, String)] {
        [
            ("Market Cap", priceModel.formatPrice(lamports: (tokenModel.prices.last?.price ?? 0) * (tokenModel.token.supply ?? 0) / Int(pow(10.0, Double(tokenModel.token.decimals ?? 0))))),
            ("Volume (\(String(tokenModel.token.volume?.interval ?? "30s")))", formatLargeNumber(Double(tokenModel.token.volume?.value ?? 0) / 1e9)), // TODO: fix volume calculation
            ("Holders", "53.3K"), // TODO: Add holders data?
            ("Supply", formatLargeNumber(Double(tokenModel.token.supply ?? 0) / pow(10.0, Double(tokenModel.token.decimals ?? 0))))
        ]
    }
    
    enum Timespan: String, CaseIterable {
        case live = "LIVE"
        case thirtyMin = "30M"
        
        var interval: Interval {
            switch self {
                case .live: return "1m"
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
        tokenModel.buyTokens(buyAmountLamps: buyAmountLamps) { success in
            if success {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBuySheet = false
                    activeTab = "sell" //  Switch tab after successful buy
                }
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
                infoCardLowOpacity
                    .opacity(0.5) // Adjust opacity here
                    .padding(.horizontal, 8)
                    .padding(.bottom, -4)

                BuySellForm(
                    tokenModel: tokenModel,
                    activeTab: $activeTab,
                    showBuySheet: $showBuySheet,
                    defaultAmount: $defaultAmount
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
                if tokenModel.token.imageUri != nil {
                    ImageView(imageUri: tokenModel.token.imageUri!, size: 20)
                }
                Text("$\(tokenModel.token.symbol ?? "")")
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
                ChartView(prices: tokenModel.prices, timeframeSecs: 90.0, purchaseTime: tokenModel.purchaseTime, purchaseAmount: tokenModel.balanceLamps)
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
    
    private func intervalButton(for timespan: Timespan) -> some View {
        Button {
            withAnimation {
                selectedTimespan = timespan
                tokenModel.updateHistoryInterval(timespan.interval)
            }
        } label: {
            HStack {
                if timespan == .live {
                    Circle()
                        .fill(AppColors.red)
                        .frame(width: 10, height: 10)
                }
                Text(timespan.rawValue)
                    .font(.sfRounded(size: .base, weight: .semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(selectedTimespan == timespan ? AppColors.aquaBlue : Color.clear)
            .foregroundColor(selectedTimespan == timespan ? AppColors.black : AppColors.white)
            .cornerRadius(6)
        }
    }
    
    private var infoCardLowOpacity: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            Text("Stats")
                .font(.sfRounded(size: .xl, weight: .semibold))
                .foregroundColor(AppColors.white)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            // grid
            ForEach(0..<stats.count/2, id: \.self) { index in
                HStack(alignment: .top, spacing: 20) {
                    ForEach(0..<2) { subIndex in
                        let stat = stats[index * 2 + subIndex]
                        VStack {
                            HStack(alignment: .center)  {
                                Text(stat.0)
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundColor(AppColors.gray)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Text(stat.1)
                                    .font(.sfRounded(size: .base, weight: .semibold))
                                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                                    .foregroundColor(AppColors.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            //divider
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 0.5)
                                .background(AppColors.gray.opacity(0.5))
                        }
                    }
                }
                .padding(.top,8)
                .padding(.horizontal,8)
            }
        }
        .padding(.horizontal,24)
        .padding(.vertical,16)
        .frame(maxWidth: .infinity, maxHeight: 95 ,alignment: .topLeading)
        .background(AppColors.darkGrayGradient)
        .cornerRadius(12)
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
                    TokenInfoCardView(tokenModel: tokenModel, isVisible: $showInfoCard)
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
}

