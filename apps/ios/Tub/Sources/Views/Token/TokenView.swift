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
    
    var body: some View {
        ZStack(alignment: .bottom) {


            VStack () {
                VStack (alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading, spacing: -2) {
                            HStack {
                                Image(systemName: "pencil")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.white)
                                
                                Text("$\(tokenModel.token.symbol) (\(tokenModel.token.name))")
                                    .font(.sfRounded(size: .base, weight: .bold))
                            }
                            Text("\(tokenModel.prices.last?.price ?? 0, specifier: "%.3f") SOL")
                                .font(.sfRounded(size: .xl4, weight: .bold))
                        }
                        
                        Spacer() // Add this to push the chevron to the right
                        
                        Image(systemName: "chevron.down")
                            .resizable()
                            .frame(width: 30, height: 15)
                            .foregroundColor(.white)
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
                                            .fill(Color.red)
                                            .frame(width: 10, height: 10)
                                    }
                                    Text(timespan.rawValue)
                                        .font(.sfRounded(size: .base, weight: .semibold))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(selectedTimespan == timespan ? neonBlue : Color.clear)
                                .foregroundColor(selectedTimespan == timespan ? Color.black : Color.white)
                                .cornerRadius(6)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    BuySellForm(tokenModel: tokenModel, activeTab: $activeTab)
                    
                }.padding(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear) // Keep this clear

            // Info Card View (slide-up effect)
            if showInfoCard {
                // Fullscreen tap dismiss
                Color.black.opacity(0.4) // Semi-transparent background
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
}


#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    @Previewable @State var activeTab: String = "buy"
    TokenView(tokenModel: TokenModel(userId: userId, tokenId: mockTokenId), activeTab: $activeTab)
        .environmentObject(UserModel(userId: userId))
}
