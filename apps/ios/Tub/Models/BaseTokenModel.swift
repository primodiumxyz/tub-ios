import SwiftUI

class BaseTokenModel: ObservableObject {
    var tokenId: String = ""
    var userId: String = ""
    var token: Token = Token(id: "", name: "COIN", symbol: "SYMBOL")
    
    @Published var netWorth: Double = 0
    @Published var solBalance: Double = 0
    @Published var tokenBalance: Double = 0
    @Published var tokensBought: Double = 0
    @Published var prices: [Price] = [] {
        didSet {
            recalculateNetWorth()
        }
    }

    @Published var loading = true
    
    func buyTokens(buyAmountSol: Double, completion: ((Bool) -> Void)?) {}
    
    func sellTokens(completion: ((Bool) -> Void)?) {}
    
    private func recalculateNetWorth() {
        guard let currentPrice = prices.last?.price else { return }
        netWorth = solBalance + (tokenBalance * currentPrice)
    }
}
