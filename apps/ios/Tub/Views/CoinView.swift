//
//  ExploreView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import SwiftUI
import Combine

struct CoinData {
    var name: String
    var symbol: String
}

struct Price: Identifiable {
    var id = UUID()
    var timestamp: Date
    var price: Double
}

struct CoinView: View {
    @ObservedObject var coinModel: CoinDisplayViewModel = CoinDisplayViewModel(coinData:CoinData(name: "PEPE", symbol: "PEP"))

   var body: some View {
       VStack (alignment: .leading) {
        VStack (alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Your Net Worth")
                    .font(.subheadline)
                    .opacity(0.5)
                Text("\(coinModel.balance, specifier: "%.2f") SOL")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                
                if coinModel.balance != 1000 {
                    Text(coinModel.balance > 1000 ? "+\(coinModel.balance - 1000, specifier: "%.2f") SOL" : "-\(1000 - coinModel.balance, specifier: "%.2f") SOL")
                        .foregroundColor(coinModel.balance > 1000 ? .green : .red)
                }
            }
            .padding(.bottom, 32)
            HStack {
                Image(systemName: "bitcoinsign.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                    .background(Color.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 10)) // This will round the corners
              
                VStack(alignment: .leading){
                    Text("\(coinModel.coinData.name) (\(coinModel.coinData.symbol.uppercased()))") // Update this line
                        .font(.headline)
                    Text("\(coinModel.prices.last?.price ?? 0, specifier: "%.3f") SOL")
                        .font(.title)
                        .fontWeight(.bold)
           

                }
            }
            
            ChartView(prices: coinModel.prices).padding()
            VStack {
               Text("Your \(coinModel.coinData.symbol.uppercased()) Balance") // Update this line
                   .font(.subheadline)
                   .opacity(0.5)
               Text("\(coinModel.coinBalance, specifier: "%.3f") \(coinModel.coinData.symbol.uppercased())") // Update this line
                   .font(.title2)
                   .fontWeight(.bold)
           }
           
           BuySellForm(viewModel: coinModel)
         
        }.padding(8)
       }
       .frame(maxWidth: .infinity, maxHeight: .infinity) // Add this line
       .background(.black)
       .foregroundColor(.white)
       
    }
}


#Preview {
    CoinView()
}
