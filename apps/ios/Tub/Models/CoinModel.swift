//
//  CoinModel.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import SwiftUI
import Combine

class CoinDisplayViewModel: ObservableObject {
    @Published var balance: Double = 1000
    @Published var coinBalance: Double = 0
    @Published var buyAmountUSD: Double = 10
    @Published var amountBought: Double = 0
    @Published var prices: [Price] = []
    
    var coinData: CoinData
    
    init(coinData: CoinData) {
        self.coinData = coinData
        generateInitialPrice()
        startPriceUpdates()
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
    
    func handleBuy() -> Bool {
        guard let currentPrice = prices.last?.price else { return false }
        let tokenAmount = buyAmountUSD / currentPrice
        print("amount bought:", buyAmountUSD, tokenAmount)
        if buyAmountUSD <= 0 || buyAmountUSD > balance {
            return false
        }
        balance -= buyAmountUSD
        coinBalance += tokenAmount
        amountBought += buyAmountUSD
        buyAmountUSD = 0
        return true
    }
    
    func handleSell() {
        guard let currentPrice = prices.last?.price else { return }
        if coinBalance <= 0 {
            return
        }
        balance += coinBalance * currentPrice
        coinBalance = 0
        amountBought = 10
    }
}
