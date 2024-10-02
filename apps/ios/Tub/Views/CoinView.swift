//
//  ExploreView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import SwiftUI
import Combine


struct CoinView: View {
    @ObservedObject var coinModel: CoinDisplayViewModel = CoinDisplayViewModel(coinData:CoinData(name: "MONKAY", symbol: "MONK"))

   var body: some View {
       VStack () {
        VStack (alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Your Net Worth")
                    .font(.sfRounded(size: .sm, weight: .bold))
                    .opacity(0.7)
                    .kerning(-1)
                Text("\(coinModel.balance, specifier: "%.2f") SOL")
                    .font(.sfRounded(size: .xl4))
                    .fontWeight(.bold)
//                if coinModel.balance != 1000 {
                    HStack(spacing:3) {
                        Text(coinModel.balance > 1000 ? "+ \(coinModel.balance - 1000, specifier: "%.2f") SOL" : "- \(1000 - coinModel.balance, specifier: "%.2f") SOL")
                            .font(.sfRounded(size: .base, weight: .bold))
                        
                        HStack(spacing: 2) {
                            Image(systemName: coinModel.balance > 1000 ? "arrow.up.right" : "arrow.down.right")
                                .foregroundColor(coinModel.balance > 1000 ? .green : .red)
                                .kerning(-1)

                            Text("\(abs((coinModel.balance - 1000) / 1000 * 100), specifier: "%.2f")%")
                                .foregroundColor(coinModel.balance > 1000 ? .green : .red)
                                .font(.sfRounded(size: .base, weight: .bold))
                                .kerning(-1)
                        }
                    }
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
                    Text("$\(coinModel.coinData.symbol) (\(coinModel.coinData.name))") // Update this line
                        .font(.sfRounded(size: .base, weight: .bold))
                    Text("\(coinModel.prices.last?.price ?? 0, specifier: "%.3f") SOL")
                        .font(.sfRounded(size: .xl3, weight: .bold))


                }.foregroundColor(Color(red: 1, green: 0.92, blue: 0.52))
            }
            
            ChartView(prices: coinModel.prices)
            VStack(alignment: .leading) {
               Text("Your \(coinModel.coinData.symbol.uppercased()) Balance") // Update this line
                .font(.sfRounded(size: .sm, weight: .bold))
                    .opacity(0.7)
                    .kerning(-1)
                
               Text("\(coinModel.coinBalance, specifier: "%.3f") \(coinModel.coinData.symbol.uppercased())") // Update this line
                    .font(.sfRounded(size: .xl2, weight: .bold))
           }
           
           BuySellForm(viewModel: coinModel)
         
        }.padding(8)
       }
       .frame(maxWidth: .infinity) // Add this line
       .background(.black)
       .foregroundColor(.white)
       
    }
}


#Preview {
    CoinView()
}
