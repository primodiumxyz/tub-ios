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
            VStack(alignment: .leading) {
                tokenInfoView
                chartView
                intervalButtons
                Spacer()
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
        VStack(alignment: .leading) {
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
        .padding(.horizontal)
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
        .padding(.bottom, 8)
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
    
    private var infoCardOverlay: some View {
        Group {
            if showInfoCard {
                // Fullscreen tap dismiss
                AppColors.black.opacity(0.4) // Semi-transparent background
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            showInfoCard = false // Close the card
                        }
                    }
                
                TokenInfoCardView(tokenModel: tokenModel, isVisible: $showInfoCard)
                    .transition(.move(edge: .bottom))
                    .zIndex(1) // Ensure it stays on top
            }
        }
    }
    
    
    private var buySheetOverlay: some View {
        Group {
            if showBuySheet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            print("CLOSING")
                            showBuySheet = false
                        }
                    }
                
                BuyForm(isVisible: $showBuySheet, defaultAmount: $defaultAmount, tokenModel: tokenModel, onBuy: handleBuy)
                    .transition(.move(edge: .bottom))
                    .zIndex(2) // Ensure it stays on top of everything
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

