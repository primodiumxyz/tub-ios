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
    @EnvironmentObject private var userModel: UserModel
    @State private var showInfoCard = false
    @State private var selectedTimespan: Timespan = .live
    @Binding var activeTab: String
    @State private var showBuySheet: Bool = false

    enum Timespan: String {
        case live = "LIVE"
        case thirtyMin = "30M"
        
        var interval: String {
            switch self {
            case .live: return "30s"
            case .thirtyMin: return "30m"
            }
        }
    }
    
    init(tokenModel: TokenModel, activeTab: Binding<String>) {
        self.tokenModel = tokenModel
        self._activeTab = activeTab
    }
    
    func handleBuy(amount: Int, completion: ((Bool) -> Void)?) {
        tokenModel.buyTokens(buyAmountLamps: amount, completion: {success in
            print("success", success)
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
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                if tokenModel.token.imageUri != nil {
                                    ImageView(imageUri: tokenModel.token.imageUri!, size: 20)
                                }
                                Text("$\(tokenModel.token.symbol)")
                                    .font(.sfRounded(size: .lg, weight: .semibold))
                            }
                            Text(PriceFormatter.formatPrice(lamports: tokenModel.prices.last?.price ?? 0) + " SOL")
                                .font(.sfRounded(size: .xl4, weight: .bold))
                            
                            HStack {
                                Text(tokenModel.priceChange.amountLamps >= 0 ? "+" : "-")
                                Text(PriceFormatter.formatPrice(lamports: tokenModel.priceChange.amountLamps, showSign: false) + " SOL")
                                Text("(\(tokenModel.priceChange.percentage, specifier: "%.1f")%)")
                                
                                Text("30s").foregroundColor(.gray)
                            }
                            .font(.sfRounded(size: .sm, weight: .semibold))
                            .foregroundColor(tokenModel.priceChange.amountLamps >= 0 ? .green : .red)
                        }
                        
                        Spacer() // Add this to push the chevron to the right
                        
                        Image(systemName: "chevron.down")
                            .resizable()
                            .frame(width: 20, height: 10)
                            .foregroundColor(AppColors.white)
                            .rotationEffect(Angle(degrees: showInfoCard ? 180 : 0)) // Add this line
                    }
                    .onTapGesture {
                        
                        // Toggle the info card
                        withAnimation(.easeInOut) {
                            showInfoCard.toggle()
                        }
                    }

                    // Replace the existing ChartView with this conditional rendering
                    if selectedTimespan == .live {
                        ChartView(prices: tokenModel.prices, purchaseTime: tokenModel.purchaseTime, purchaseAmount: tokenModel.balanceLamps)
                    } else {
                        CandleChartView(prices: tokenModel.prices, intervalSecs: 90, timeframeMins: 30)
                            .id(tokenModel.prices.count)
                    }

                    HStack {
                        Spacer()
                        ForEach([Timespan.live, Timespan.thirtyMin], id: \.self) { timespan in
                            Button(action: {
                                selectedTimespan = timespan
                                tokenModel.updateHistoryInterval(interval: timespan.interval)
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
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    Spacer()
                    BuySellForm(tokenModel: tokenModel, activeTab: $activeTab, showBuySheet: $showBuySheet)
                    
                }.padding(8)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(AppColors.white)
            
            // Info Card View (slide-up effect)
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

            // Buy Sheet View
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
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Full screen layout for ZStack
    }
}


#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    @Previewable @State var activeTab: String = "buy"
    @Previewable @State var tokenId: String = "exampleTokenId"
    TokenView(tokenModel: TokenModel(userId: userId, tokenId: tokenId), activeTab: $activeTab).background(.black)
        .environmentObject(UserModel(userId: userId))
}
