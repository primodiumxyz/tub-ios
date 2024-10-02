import SwiftUI
import Apollo
import TubAPI

class RemoteCoinModel: BaseCoinModel{
    
    required override init(tokenId: String) {
        super.init(tokenId: "")
        
    }
    
    override func handleBuy(buyAmountUSD: CGFloat) -> Bool {
        return false;
    }
    
    override func handleSell() {
        print("selling")
    }
    
    func fetchCoins() async throws {
        throw NSError(domain: "CoinModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "fetchCoins() not implemented yet"])
    }

    func addCoin(_ coin: Coin) async throws {
        throw NSError(domain: "CoinModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "addCoin() not implemented yet"])
    }

    func updateCoin(_ coin: Coin) async throws {
        throw NSError(domain: "CoinModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "updateCoin() not implemented yet"])
    }

    func deleteCoin(_ coin: Coin) async throws {
        throw NSError(domain: "CoinModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "deleteCoin() not implemented yet"])
    }
}
