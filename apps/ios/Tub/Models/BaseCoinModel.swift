import SwiftUI

class BaseCoinModel: ObservableObject {
    var tokenId: String
    var coin: Coin = Coin(id: "", name: "COIN", symbol: "SYMBOL")
    
    @Published var balance: Double = 0
    @Published var coinBalance: Double = 0
    @Published var amountBought: Double = 0
    @Published var prices: [Price] = []

    @Published var loading = true
    
    init(tokenId: String) {
        self.tokenId = tokenId
    }
    
    func buyTokens(buyAmount: Double) -> Bool {
        return false
    }
    
    func sellTokens() -> Bool {
        return false
    }
}
