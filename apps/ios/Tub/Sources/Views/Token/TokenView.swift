//
//  ExploreView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import SwiftUI
import Combine




struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .font(.sfRounded(size: .base))
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(.white)
    }
}

struct TokenView : View {
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject private var userModel: UserModel
    @State private var showInfoCard = false
    
    init(tokenModel: TokenModel) {
        self.tokenModel = tokenModel
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack () {
                VStack (alignment: .leading) {
                    HStack {
                        Image(systemName: "bittokensign.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10)) // This will round the corners
                        
                        VStack(alignment: .leading){
                            Text("$\(tokenModel.token.symbol) (\(tokenModel.token.name))") // Update this line
                                .font(.sfRounded(size: .base, weight: .bold))
                            Text("\(tokenModel.prices.last?.price ?? 0, specifier: "%.3f") SOL")
                                .font(.sfRounded(size: .xl3, weight: .bold))
                            
                            
                        }.foregroundColor(Color(red: 1, green: 0.92, blue: 0.52))
                    }.onTapGesture {
                        // Toggle the info card visibility with animation
                        withAnimation(.easeInOut) {
                            showInfoCard.toggle()
                        }
                    }
                    
                    ChartView(prices: tokenModel.prices)
                    VStack(alignment: .leading) {
                        Text("Your \(tokenModel.token.symbol.uppercased()) Balance") // Update this line
                            .font(.sfRounded(size: .sm, weight: .bold))
                            .opacity(0.7)
                            .kerning(-1)
                        
                        Text("\(tokenModel.tokenBalance.total, specifier: "%.3f") \(tokenModel.token.symbol.uppercased())") // Update this line
                            .font(.sfRounded(size: .xl2, weight: .bold))
                    }
                    
                    BuySellForm(tokenModel: tokenModel)
                    
                }.padding(8)
            }
            .frame(maxWidth: .infinity) // Add this line
            .background(.black)
            .foregroundColor(.white)
            
            // Info Card View (slide-up effect)
            if showInfoCard {
                TokenInfoCardView(tokenModel: tokenModel, isVisible: $showInfoCard)
                    .transition(.move(edge: .bottom))
                    .zIndex(1) // Ensure it stays on top
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Full screen layout for ZStack
        .background(Color.black.ignoresSafeArea())
    }
}


#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    TokenView(tokenModel: TokenModel(userId: userId, tokenId: mockTokenId))
        .environmentObject(UserModel(userId: userId))
}
