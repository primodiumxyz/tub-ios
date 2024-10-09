//
//  BuySellForm.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//
import SwiftUI

struct BuySellForm: View {
    @ObservedObject var tokenModel: BaseTokenModel
    @State private var activeTab: String = "buy"
    @State private var sellAmount: Double = 0.0

    func handleBuy(amount: Double, completion: ((Bool) -> Void)?) {
        tokenModel.buyTokens(buyAmountSol: amount, completion: {success in
            if success {
                activeTab = "sell"
            }
            completion?(success)
        })
    }
    
    func handleSell(completion: ((Bool) -> Void)?) {
        tokenModel.sellTokens(completion: {success in
            if success {
                activeTab = "buy"
            }
            completion?(success)
        })
    }
    
    var body: some View {
        VStack {
            if activeTab == "buy" {
                BuyForm(tokenModel: tokenModel, onBuy: handleBuy)
            } else {
                SellForm(tokenModel: tokenModel, onSell: handleSell)
            }
        }.frame(width: .infinity, height: 300)
    }
}

#Preview {
    VStack {
        BuySellForm(tokenModel: MockTokenModel())
    }.frame(maxWidth: .infinity, maxHeight: .infinity) .background(.black).foregroundColor(.white)
}

