//
//  CoinModel.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import SwiftUI
import Combine

class LocalCoinModel: BaseCoinModel {
    
    override required init() {
        super.init()
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
    
    override func buyTokens(buyAmount: Double, completion: ( (Bool) -> Void)? ) {
        guard let currentPrice = prices.last?.price else {
            completion?(false)
            return
        }
        
        let tokenAmount = buyAmount / currentPrice
        if buyAmount <= 0 || buyAmount > balance {
            completion?(false)
        }
        balance -= buyAmount
        coinBalance += tokenAmount
        amountBought += buyAmount
        completion?(true)
    }
    
    override func sellTokens(completion: ((Bool) -> Void)?) {
        guard let currentPrice = prices.last?.price else {
            completion?(false)
            return
        }
        
        if coinBalance <= 0 {
            completion?(false)
        }
        balance += amountBought * currentPrice
        coinBalance = 0
        amountBought = 0
        completion?(true)
    }
}
