//
//  BuySellForm.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//
import SwiftUI

struct BuySellForm: View {
    @ObservedObject var viewModel: CoinDisplayViewModel
    @State private var activeTab: String = "buy"
    
    var body: some View {
        VStack {
            if activeTab == "buy" {
                VStack {
                    Slider(value: $viewModel.buyAmountUSD, in: 0...viewModel.balance, step: 1)
                    Text("\(viewModel.buyAmountUSD, specifier: "%.2f") SOL")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Add token conversion display
                    if let currentPrice = viewModel.prices.last?.price, currentPrice > 0 {
                        let tokenAmount = viewModel.buyAmountUSD / currentPrice
                        Text("\(tokenAmount, specifier: "%.4f") \(viewModel.coinData.symbol)")
                            .font(.subheadline)
                            .opacity(0.5)
                    }
                    
                    Button(action: {
                        viewModel.handleBuy()
                        activeTab = "sell"
                    }) {
                        Text("Buy")
                            .font(.headline)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            } else {
                VStack {
                    Button(action: {
                        viewModel.handleSell()
                        activeTab = "buy"
                    }) {
                        Text("Sell")
                            .font(.headline)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Text("$\(viewModel.coinBalance * (viewModel.prices.last?.price ?? 0) - viewModel.amountBought, specifier: "%.2f")")
                        .foregroundColor(viewModel.coinBalance * (viewModel.prices.last?.price ?? 0) - viewModel.amountBought > 0 ? .green : .red)
                }
            }
        }
    }
}

#Preview {
    @ObservedObject var coinModel: CoinDisplayViewModel = CoinDisplayViewModel(coinData:CoinData(name: "PEPE", symbol: "PEP"))
    return BuySellForm(viewModel: coinModel)
}
