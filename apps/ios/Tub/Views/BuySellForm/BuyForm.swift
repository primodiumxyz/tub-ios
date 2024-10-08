//
//  BuyForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct BuyForm: View {
    @ObservedObject var coinModel: BaseCoinModel
    var onBuy: (Double, ((Bool) -> Void)?) -> ()
    @State private var buyAmountString: String = ""
    @State private var buyAmountSol: Double = 0.0
    @State private var isValidInput: Bool = true

    func handleBuy() {
        let _ = onBuy(buyAmountSol, {_ in
            buyAmountString = ""
            buyAmountSol = 0   
        })
    }

    var body: some View {
        VStack {
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Buy")
                            .font(.sfRounded(size: .xl2, weight: .semibold))
                    }
                    VStack(alignment: .trailing, spacing: 0) {
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
                                        buyAmountSol = amount
                                        isValidInput = true
                                    } else {
                                        isValidInput = false
                                    }
                                }
                                .foregroundColor(isValidInput ? .white : .red)
                            if buyAmountString != "" {
                                Text(coinModel.coin.symbol)
                            }
                        }
                        .font(.sfRounded(size: .xl3, weight: .bold))
                        
                        // Add token conversion display
                        if let currentPrice = coinModel.prices.last?.price, currentPrice > 0 {
                            let tokenAmount = buyAmountSol * currentPrice
                            Text("\(tokenAmount, specifier: "%.4f") SOL")
                                .font(.sfRounded(size: .base, weight: .bold))
                                .opacity(0.8)
                        }
                    }
                    
                    if coinModel.balance > 0 {
                        SliderWithPoints(value: $buyAmountSol, in: 0...coinModel.balance, step: 1)
                            .onChange(of: buyAmountSol) { newValue in
                                if newValue.truncatingRemainder(dividingBy: 1) == 0 {
                                    buyAmountString = String(format: "%.0f", newValue)
                                } else {
                                    buyAmountString = String(newValue)
                                }
                            }
                    }
                    SwipeToEnterView(text: "Slide to buy", onUnlock: handleBuy, disabled: buyAmountSol == 0 || buyAmountString == "")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
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
                .cornerRadius(30)
            )
        }
        .frame(width: .infinity, height: 300)
    }
}

#Preview {
    VStack {
        BuyForm(coinModel: LocalCoinModel(), onBuy: { _, _ in })
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
    .foregroundColor(.white)
}

