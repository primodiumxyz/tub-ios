import SwiftUI

class BaseCoinModel: ObservableObject {
    var tokenId: String
    var userId: String
    var coin: Coin = Coin(id: "", name: "COIN", symbol: "SYMBOL")
    
    @Published var balance: Double = 0
    @Published var coinBalance: Double = 0
    @Published var amountBought: Double = 0
    @Published var prices: [Price] = []

    @Published var loading = true
    
    init(userId: String, tokenId: String) {
        self.userId = userId
        self.tokenId = tokenId
    }
    
    func buyTokens(buyAmount: Double, completion: ((Bool) -> Void)?) {}
    
    func sellTokens(completion: ((Bool) -> Void)?) {}
}
