//
//  TokenModel.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//

import SwiftUI
import Combine

class MockTokenModel: BaseTokenModel {
    
    override required init() {
        super.init()
        token = Token(id: "", name: "MONKEY" ,symbol: "MONK")
        solBalance = 1000
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
    
    override func buyTokens(buyAmountSol: Double, completion: ( (Bool) -> Void)? ) {
        guard let currentPrice = prices.last?.price else {
            completion?(false)
            return
        }
        
        let tokenAmount = buyAmountSol * currentPrice
        if buyAmountSol <= 0 || buyAmountSol > solBalance {
            completion?(false)
        }
        solBalance -= buyAmountSol
        tokenBalance += tokenAmount
        amountBoughtSol += buyAmountSol
        print("amount bought: \(amountBoughtSol)")
        completion?(true)
    }
    
    override func sellTokens(completion: ((Bool) -> Void)?) {
        guard let currentPrice = prices.last?.price else {
            completion?(false)
            return
        }
        
        if tokenBalance <= 0 {
            completion?(false)
        }
        solBalance += amountBoughtSol * currentPrice
        tokenBalance = 0
        amountBoughtSol = 0
        completion?(true)
    }
}
