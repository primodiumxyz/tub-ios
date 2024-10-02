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
    @State private var buyAmountString: String = "0"
    @State private var buyAmountUSD: Double = 0.0
    @State private var isValidInput: Bool = true

    func handleBuy() {
        let success = viewModel.handleBuy(buyAmountUSD: buyAmountUSD)
        if(!success) {return}
        activeTab = "sell"
        buyAmountString=""
        buyAmountUSD=0
    }
    
    var body: some View {
        VStack {
            if activeTab == "buy" {
                VStack {
                    VStack (alignment: .leading){
                        HStack(){
                            Text("Buy")
                                .font(.sfRounded(size: .xl2, weight: .semibold))
                        }
                        VStack(alignment: .trailing, spacing: 0){
                            HStack {
                                TextField("Enter amount", text: $buyAmountString)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: buyAmountString) { newValue in
                                        let filtered = newValue.filter { "0123456789.".contains($0) }
                                        if filtered != newValue {
                                            buyAmountString = filtered
                                        }
                                        
                                        if let amount = Double(filtered), amount >= 0 {
                                            buyAmountUSD = amount
                                            isValidInput = true
                                        } else {
                                            isValidInput = false
                                        }
                                    }
                                    .foregroundColor(isValidInput ? .white : .red)
                                if buyAmountString != ""{
                                    Text("SOL")
                                }
                            }.font(.sfRounded(size: .xl3, weight: .bold))
                                

                            
                            // Add token conversion display
                            if let currentPrice = viewModel.prices.last?.price, currentPrice > 0 {
                                let tokenAmount = buyAmountUSD / currentPrice
                                Text("\(tokenAmount, specifier: "%.4f") \(viewModel.coinData.symbol)")
                                
                                    .font(.sfRounded(size: .base, weight: .bold))
                                    .opacity(0.8)
                            }
                        }
                        
                        SliderWithPoints(value: $buyAmountUSD, in: 0...viewModel.balance, step: 1)
                            .onChange(of: buyAmountUSD) { newValue in
                                buyAmountString = String(format: "%.2f", newValue)
                            }
                        SwipeToEnterView(text: "Slide to buy", onUnlock: handleBuy, disabled: buyAmountString == "0")
                        
                        
                    }.padding(.horizontal, 20).padding(.vertical, 20)
                }
                .frame(height: 270)
                .background(
                LinearGradient(
                stops: [
                Gradient.Stop(color: Color(red: 0.7, green: 0.54, blue: 0.79).opacity(0.65), location: 0.00),
                Gradient.Stop(color: Color(red: 0.31, green: 0.62, blue: 0.78).opacity(0.9), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0, y: 0.5),
                endPoint: UnitPoint(x: 1, y: 1)
                )
                )
                .cornerRadius(30)
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
        }.frame(width: .infinity, height: 300)
    }
}

#Preview {
    @ObservedObject var coinModel: CoinDisplayViewModel = CoinDisplayViewModel(coinData:CoinData(name: "PEPE", symbol: "PEP"))
    return VStack {BuySellForm(viewModel: coinModel)
    }.frame(maxWidth: .infinity, maxHeight: .infinity) .background(.black).foregroundColor(.white)
    }
    
