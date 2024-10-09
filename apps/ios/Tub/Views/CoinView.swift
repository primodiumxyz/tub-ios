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

struct CoinView : View {
    @ObservedObject var coinModel: BaseCoinModel
    @EnvironmentObject private var userModel: UserModel
    init(coinModel: BaseCoinModel) {
        self.coinModel = coinModel
    }
    
    var body: some View {
       VStack () {
        VStack (alignment: .leading) {
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
    CoinView(coinModel: LocalCoinModel())
}
