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
    @State private var buyAmountString: String = ""

    init(viewModel: CoinDisplayViewModel) {
        self.viewModel = viewModel
        // Initialize buyAmountString with the viewModel's buyAmountUSD
        _buyAmountString = State(initialValue: String(format: "%.2f", viewModel.buyAmountUSD))
    }
    
    func handleBuy() {
        let success = viewModel.handleBuy()
        if(!success) {return}
        activeTab = "sell"
    }
    
    var body: some View {
        VStack {
            if activeTab == "buy" {
                VStack {
                    VStack (alignment: .leading){
                        HStack(){
                            Text("Amount")
                        }
                        VStack(alignment: .trailing){
                            TextField("Enter amount", text: $buyAmountString)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: buyAmountString) { newValue in
                                    if let amount = Double(newValue) {
                                        viewModel.buyAmountUSD = amount
                                    }
                                }
                            
                            
                            // Add token conversion display
                            if let currentPrice = viewModel.prices.last?.price, currentPrice > 0 {
                                let tokenAmount = viewModel.buyAmountUSD / currentPrice
                                Text("\(tokenAmount, specifier: "%.4f") \(viewModel.coinData.symbol)")
                                    .font(.subheadline)
                                    .opacity(0.5)
                            }
                        }
                        SwipeToEnterView(text: "Slide to buy", onUnlock: handleBuy, disabled : viewModel.buyAmountUSD == 0)
                        
                        
                    }.padding(16)
                }.background(Color.white.opacity(0.3)).cornerRadius(24)
            } else {
                HStack {
                    Spacer()
                    VStack {
                        Button(action: {
                            viewModel.handleSell()
                            activeTab = "buy"
                        }) {
                            Text("Sell")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(Color.white.opacity(0.5))
                                .clipShape(Circle())
                        }
                        Text("$\(viewModel.coinBalance * (viewModel.prices.last?.price ?? 0) - viewModel.amountBought, specifier: "%.2f")")
                            .foregroundColor(viewModel.coinBalance * (viewModel.prices.last?.price ?? 0) - viewModel.amountBought > 0 ? .green : .red)
                    }
                    Spacer()
                }.padding(12)
            }
        }.frame(height: 250)
    }
}

#Preview {
    @ObservedObject var coinModel: CoinDisplayViewModel = CoinDisplayViewModel(coinData:CoinData(name: "PEPE", symbol: "PEP"))
    return VStack {BuySellForm(viewModel: coinModel)
    }.frame(maxWidth: .infinity, maxHeight: .infinity) .background(.black).foregroundColor(.white)
    }
    
