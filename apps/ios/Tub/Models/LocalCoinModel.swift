//
//  CoinModel.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import SwiftUI
import Combine

class LocalCoinModel: BaseCoinModel {
    
    required override init(tokenId: String) {
        super.init(tokenId: tokenId)
        coin = Coin(id: "", name: "MONKEY" ,symbol: "MONK")
        balance = 1000
        generateInitialPrice()
        startPriceUpdates()
        loading = false
    }
    
    func generateInitialPrice() {
        let initialPrice = Price(timestamp: Date(), price: 50)
        prices.append(initialPrice)
    }
    
    func startPriceUpdates() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.updatePrice()
        }
    }
    
    func updatePrice() {
        guard let lastPrice = prices.last else { return }
        let change = lastPrice.price * (Double.random(in: -0.24...0.24))
        let newPrice = Price(timestamp: Date(), price: max(0, lastPrice.price + change))
        prices.append(newPrice)
    }
    
    override func handleBuy(buyAmountUSD: CGFloat) -> Bool {
        guard let currentPrice = prices.last?.price else { return false }
        let tokenAmount = buyAmountUSD / currentPrice
        if buyAmountUSD <= 0 || buyAmountUSD > balance {
            return false
        }
        balance -= buyAmountUSD
        coinBalance += tokenAmount
        amountBought += buyAmountUSD
        return true
    }
    
    override func handleSell() {
        guard let currentPrice = prices.last?.price else { return }
        if coinBalance <= 0 {
            return
        }
        balance += coinBalance * currentPrice
        coinBalance = 0
        amountBought = 10
    }
}
