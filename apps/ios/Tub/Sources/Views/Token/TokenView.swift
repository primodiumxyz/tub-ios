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
        
        var seconds: Double {
            switch self {
            case .live: return 30
            case .thirtyMin: return 1800 // 30 minutes in seconds
            }
        }
    }
    
    init(tokenModel: TokenModel, activeTab: Binding<String>) {
        self.tokenModel = tokenModel
        self._activeTab = activeTab
    }
    
    func handleBuy(amount: Double, completion: ((Bool) -> Void)?) {
        tokenModel.buyTokens(buyAmountSol: amount, completion: {success in
            print("success", success)
            if success {
                print("setting to sell")
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
                VStack (alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Image(systemName: "pencil")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(AppColors.white)
                                
                                Text("$\(tokenModel.token.symbol) (\(tokenModel.token.name))")
                                    .font(.sfRounded(size: .lg, weight: .semibold))
                            }
                            Text("\(tokenModel.prices.last?.price ?? 0, specifier: "%.3f") SOL")
                                .font(.sfRounded(size: .xl4, weight: .bold))
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

                    ChartView(prices: tokenModel.prices, purchaseTime: tokenModel.purchaseTime, purchaseAmount: tokenModel.tokenBalance.total)
                    HStack {
                        Spacer()
                        ForEach([Timespan.live, Timespan.thirtyMin], id: \.self) { timespan in
                            Button(action: {
                                selectedTimespan = timespan
                                tokenModel.updateHistoryTimespan(timespan: timespan.seconds)
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
                    .padding(.vertical, 8)
                    
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
//        .background(AppColors.black.ignoresSafeArea())
    }
}


#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    @Previewable @State var activeTab: String = "buy"
    TokenView(tokenModel: TokenModel(userId: userId, tokenId: mockTokenId), activeTab: $activeTab)
        .environmentObject(UserModel(userId: userId))
}
