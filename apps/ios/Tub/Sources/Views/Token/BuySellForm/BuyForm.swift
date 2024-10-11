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
    
    // Add this function to update the buy amount
    func updateBuyAmount(_ amount: Double) {
        buyAmountString = String(format: "%.2f", amount)
        buyAmountSol = amount
        isValidInput = true
    }
    
    var body: some View {
        VStack {
            VStack {
                VStack(spacing: 8) {
                    HStack {
                        TextField("", text: $buyAmountString, prompt: Text("0", comment: "placeholder"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .onChange(of: buyAmountString) { newValue in
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                
                                // Limit to two decimal places
                                let components = filtered.components(separatedBy: ".")
                                if components.count > 1 {
                                    let wholeNumber = components[0]
                                    let decimal = String(components[1].prefix(2))
                                    buyAmountString = "\(wholeNumber).\(decimal)"
                                } else {
                                    buyAmountString = filtered
                                }
                                
                                if let amount = Double(buyAmountString), amount >= 0 {
                                    buyAmountSol = amount
                                    isValidInput = true
                                } else {
                                    isValidInput = false
                                }
                            }
                            .font(.sfRounded(size: .xl4, weight: .bold))
                            .foregroundColor(isValidInput ? .white : .red)
                           
                        
                        Text("SOL")
                            .font(.sfRounded(size: .xl2, weight: .bold))
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(10)
                    }
                    
                    // Add token conversion display
                    if let currentPrice = tokenModel.prices.last?.price, currentPrice > 0 {
                        let tokenAmount = buyAmountSol / currentPrice
                        Text("\(tokenAmount) \(tokenModel.token.symbol)")
                            .font(.sfRounded(size: .base, weight: .bold))
                            .opacity(0.8)
                    }
                    
                    // Add pill-shaped buttons
                    HStack(spacing: 8) {
                        ForEach([10.0, 25.0, 50.0, 100], id: \.self) { amount in
                                Button(action: {
                                    
                                    updateBuyAmount(amount * userModel.balance.total / 100)
                                }) {
                                    Text(amount == 100 ? "MAX" : "\(Int(amount))%")
                                        .font(.sfRounded(size: .base, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    SwipeToEnterView(text: "Swipe to buy", onUnlock: handleBuy, disabled: buyAmountSol == 0 || buyAmountString == "")
                        .padding(.top, 10)
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
}

