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
       VStack {
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
            HStack {
                Image(systemName: "bitcoinsign.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("\(coinModel.coinData.name) (\(coinModel.coinData.symbol.uppercased()))") // Update this line
                    .font(.headline)
            }
           Text("\(coinModel.prices.last?.price ?? 0, specifier: "%.3f") SOL")
               .font(.title)
               .fontWeight(.bold)
           
           VStack {
               Text("Your \(coinModel.coinData.symbol.uppercased()) Balance") // Update this line
                   .font(.subheadline)
                   .opacity(0.5)
               Text("\(coinModel.coinBalance, specifier: "%.3f") \(coinModel.coinData.symbol.uppercased())") // Update this line
                   .font(.title2)
                   .fontWeight(.bold)
           }
           BuySellForm(viewModel: coinModel)
           Button(action: {
                         // Handle next token action
                     }) {
                         Text("Next token")
                             .font(.headline)
                             .foregroundColor(.yellow)
                     }
                     .padding()
       }
       .frame(maxWidth: .infinity, maxHeight: .infinity) // Add this line
       .background(.black)
       .foregroundColor(.white)
    }
}


#Preview {
    CoinView()
}
