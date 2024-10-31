//
//  ExploreView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import SwiftUI
import Combine





struct TokenView : View {
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @Binding var activeTab: String
    
    @State private var showInfoCard = false
    @State private var selectedTimespan: Timespan = .live
    @State private var showBuySheet: Bool = false
    
    enum Timespan: String {
        case live = "LIVE"
        case thirtyMin = "30M"
        
        var interval: Double {
            switch self {
            case .live: return 120.0
            case .thirtyMin: return 30.0 * 60.0
            }
        }
    }
    
    init(tokenModel: TokenModel, activeTab: Binding<String>) {
        self.tokenModel = tokenModel
        self._activeTab = activeTab
    }
    
    func handleBuy(amount: Int, completion: ((Bool) -> Void)?) {
        tokenModel.buyTokens(buyAmountLamps: amount, completion: {success in
            if success {
                showBuySheet = false
                activeTab = "sell"
            }
            completion?(success)
        })
    }
    
    var body: some View {
        ZStack {
            // Main content
            VStack(alignment: .leading) {
                tokenInfoView
                chartView
                timespanButtons
                Spacer()
                BuySellForm(tokenModel: tokenModel, activeTab: $activeTab, showBuySheet: $showBuySheet)
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
                Text("$\(tokenModel.token.symbol)")
                    .font(.sfRounded(size: .lg, weight: .semibold))
            }
            Text(priceModel.formatPrice(lamports: tokenModel.prices.last?.price ?? 0, maxDecimals: 9, minDecimals: 2))
                .font(.sfRounded(size: .xl4, weight: .bold))
            
            HStack {
                Text(priceModel.formatPrice(lamports: tokenModel.priceChange.amountLamps, showSign: true))
                Text("(\(tokenModel.priceChange.percentage, specifier: "%.1f")%)")
                
                Text("30s").foregroundColor(.gray)
            }
            .font(.sfRounded(size: .sm, weight: .semibold))
            .foregroundColor(tokenModel.priceChange.amountLamps >= 0 ? .green : .red)
        }
    }

    private var chartView: some View {
        Group {
            if selectedTimespan == .live {
                ChartView(prices: tokenModel.prices, timeframeSecs: 90.0, purchaseTime: tokenModel.purchaseTime, purchaseAmount: tokenModel.balanceLamps)
            } else {
                CandleChartView(prices: tokenModel.prices, intervalSecs: 90, timeframeMins: 30)
                    .id(tokenModel.prices.count)
            }
        }
    }

    private var timespanButtons: some View {
        HStack {
            Spacer()
            HStack {
                ForEach([Timespan.live, Timespan.thirtyMin], id: \.self) { timespan in
                    Button(action: {
                        selectedTimespan = timespan
                        tokenModel.updateHistoryTimeframe(timespan.interval)
                    }) {
                        HStack {
                            if timespan == Timespan.live {
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
            }
            Spacer()
        }
        .padding(.bottom, 8)
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
                            showBuySheet = false
                        }
                    }
                
                BuyForm(isVisible: $showBuySheet, tokenModel: tokenModel, onBuy: handleBuy)
                    .transition(.move(edge: .bottom))
                    .zIndex(2) // Ensure it stays on top of everything
                    .offset(y: 20)
            }
        }
    }
}

