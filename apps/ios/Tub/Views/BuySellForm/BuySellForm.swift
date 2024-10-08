//
//  BuySellForm.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//
import SwiftUI

struct BuySellForm: View {
    @ObservedObject var coinModel: BaseCoinModel
    @State private var activeTab: String = "buy"
    @State private var sellAmount: Double = 0.0

    func handleBuy(amount: Double, completion: ((Bool) -> Void)?) {
        coinModel.buyTokens(buyAmount: amount, completion: {success in
            if success {
                activeTab = "sell"
            }
            completion?(success)
        })
    }
    
    func handleSell(completion: ((Bool) -> Void)?) {
        coinModel.sellTokens(completion: {success in
            if success {
                activeTab = "buy"
            }
            completion?(success)
        })
    }
    
    var body: some View {
        VStack {
            if activeTab == "buy" {
                BuyForm(coinModel: coinModel, onBuy: handleBuy)
            } else {
                SellForm(coinModel: coinModel, onSell: handleSell)
            }
        }.frame(width: .infinity, height: 300)
    }
}

#Preview {
    VStack {
        BuySellForm(coinModel: LocalCoinModel())
    }.frame(maxWidth: .infinity, maxHeight: .infinity) .background(.black).foregroundColor(.white)
}

