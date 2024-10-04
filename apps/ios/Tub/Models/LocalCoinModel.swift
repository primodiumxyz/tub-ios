//
//  CoinModel.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import SwiftUI
import Combine

class LocalCoinModel: BaseCoinModel {
    
    required init() {
        super.init(tokenId: "")
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
    
    override func buyTokens(buyAmount: Double) -> Bool {
        guard let currentPrice = prices.last?.price else { return false }
        let tokenAmount = buyAmount / currentPrice
        if buyAmount <= 0 || buyAmount > balance {
            return false
        }
        balance -= buyAmount
        coinBalance += tokenAmount
        amountBought += buyAmount
        return true
    }
    
    override func sellTokens() -> Bool {
        guard let currentPrice = prices.last?.price else { return false }
        if coinBalance <= 0 {
            return false
        }
        balance += amountBought * currentPrice
        coinBalance = 0
        amountBought = 0
        return true
    }
}
