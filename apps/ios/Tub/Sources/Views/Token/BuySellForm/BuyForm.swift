//
//  BuyForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct BuyForm: View {
    @EnvironmentObject private var userModel: UserModel
    @ObservedObject var tokenModel: TokenModel
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
                    VStack(spacing: 0) {
                        HStack {
                            TextField("Enter amount", text: $buyAmountString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
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
                                .font(.sfRounded(size: .xl4, weight: .medium))
                                .foregroundColor(isValidInput ? .white : .red)
                                
                            if buyAmountString != "" {
                                Text("SOL")
                            }
                        }
.frame(maxWidth: .infinity, alignment: .center)
                        .font(.sfRounded(size: .xl3, weight: .bold))
                        
                        // Add token conversion display
                        if let currentPrice = tokenModel.prices.last?.price, currentPrice > 0 {
                            let tokenAmount = buyAmountSol / currentPrice
                            Text("\(tokenAmount) \(tokenModel.token.symbol)")
                                .font(.sfRounded(size: .base, weight: .bold))
                                .opacity(0.8)
                        }
                    }
                  
                    SwipeToEnterView(text: "Slide to buy", onUnlock: handleBuy, disabled: buyAmountSol == 0 || buyAmountString == "")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .frame(height: 267)
            .background(
                LinearGradient(
                stops: [
                Gradient.Stop(color: Color(red: 0.18, green: 0.08, blue: 0.37), location: 0.00),
                Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.2), location: 0.71),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
                )
            )
                .cornerRadius(26)
                .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .inset(by: 0.5)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        .frame(width: .infinity, height: 300)
    }
}

