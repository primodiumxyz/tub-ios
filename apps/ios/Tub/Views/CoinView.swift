//
//  ExploreView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import SwiftUI
import Combine


struct CoinView: View {
    var localModel = false
    
    @StateObject var coinModel : BaseCoinModel
    
    init(userId: String, tokenId: String, local: Bool? = false) {
        if local != nil {
            self.localModel = local!
        }
        self._coinModel = StateObject(wrappedValue: (local ?? false) ? LocalCoinModel() : RemoteCoinModel(userId: userId, tokenId: tokenId))
    }
    
    var body: some View {
        if coinModel.loading {
            LoadingView()
        } else {
            CoinViewContent(coinModel: coinModel)
        }
    }
}



struct CoinViewContent: View {
    @ObservedObject var coinModel: BaseCoinModel
    @StateObject var userModel: UserModel
//    var initialBalance = 0.0
    
    init(coinModel: BaseCoinModel) {
        self.coinModel = coinModel
        self._userModel = StateObject(wrappedValue: UserModel(userId: coinModel.userId))
    }
    
    var body: some View {
       VStack () {
        VStack (alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Your Net Worth")
                    .font(.sfRounded(size: .sm, weight: .bold))
                    .opacity(0.7)
                    .kerning(-1)
                Text("\(userModel.balance, specifier: "%.2f") SOL")
                    .font(.sfRounded(size: .xl4))
                    .fontWeight(.bold)
//                HStack(spacing:3) {
//                   Text(userModel.balance > initialBalance ? "+ \(userModel.balance - initialBalance, specifier: "%.2f") SOL" : "- \(initialBalance - userModel.balance, specifier: "%.2f") SOL")
//                       .font(.sfRounded(size: .base, weight: .bold))
//                   
//                   HStack(spacing: 2) {
//                       Image(systemName: userModel.balance > initialBalance ? "arrow.up.right" : "arrow.down.right")
//                           .foregroundColor(userModel.balance > initialBalance ? .green : .red)
//                           .kerning(-1)
//
//                       Text("\(abs((userModel.balance - initialBalance) / initialBalance * 100), specifier: "%.2f")%")
//                           .foregroundColor(userModel.balance > initialBalance ? .green : .red)
//                           .font(.sfRounded(size: .base, weight: .bold))
//                           .kerning(-1)
//                   }
//                }
            }
            .padding(.bottom, 16)
            HStack {
                Image(systemName: "bitcoinsign.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10)) // This will round the corners

                VStack(alignment: .leading){
                    Text("$\(coinModel.coin.symbol) (\(coinModel.coin.name))") // Update this line
                        .font(.sfRounded(size: .base, weight: .bold))
                    Text("\(coinModel.prices.last?.price ?? 0, specifier: "%.3f") SOL")
                        .font(.sfRounded(size: .xl3, weight: .bold))


                }.foregroundColor(Color(red: 1, green: 0.92, blue: 0.52))
            }
            
            ChartView(prices: coinModel.prices)
            VStack(alignment: .leading) {
               Text("Your \(coinModel.coin.symbol.uppercased()) Balance") // Update this line
                .font(.sfRounded(size: .sm, weight: .bold))
                    .opacity(0.7)
                    .kerning(-1)
                
               Text("\(coinModel.coinBalance, specifier: "%.3f") \(coinModel.coin.symbol.uppercased())") // Update this line
                    .font(.sfRounded(size: .xl2, weight: .bold))
           }
           
           BuySellForm(coinModel: coinModel)
         
        }.padding(8)
       }
       .frame(maxWidth: .infinity) // Add this line
       .background(.black)
       .foregroundColor(.white)
    }
}


#Preview {
    CoinView(userId: "", tokenId: "", local: true)
}
