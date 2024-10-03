import SwiftUI
import Apollo
import TubAPI
import Combine

class RemoteCoinModel: BaseCoinModel {
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    required override init(tokenId: String) {
        print(tokenId)
        super.init(tokenId: tokenId)
        fetchInitialData()
    }
    
    private func fetchInitialData() {
        Task {
            do {
                try await fetchTokenDetails()
//                try await fetchLatestPrice()
                startPriceUpdates()
            } catch {
                print("Error fetching initial data: \(error)")
            }
        }
    }
    
    private func fetchTokenDetails() async throws {
        let query = GetAllTokensQuery()
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "RemoteCoinModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
                switch result {
                case .success(let response):
                    if let token = response.data?.token.first(where: { $0.id == self.tokenId }) {
                        DispatchQueue.main.async {
                            self.coin = Coin(id: token.id, name: token.name, symbol: token.symbol)
                            self.loading = false
                        }
                        continuation.resume()
                    } else {
                        continuation.resume(
                            throwing:
                                NSError(
                                    domain: "RemoteCoinModel",
                                    code: 1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Token not found"
                                    ]
                                )
                        )
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func subscribeToLatestPrice() async throws {
//        let query = GetLatestTokenPriceQuery(tokenId: TubAPI.Uuid(self.tokenId))
//        Network.shared.apollo.fetch(query: query) { result in
//            switch result {
//            case .success(let response):
//                 if let latestPrice = response.data?.token_price_history.last {
//                     print({latestPrice})
//                     let time = Double(latestPrice.created_at)
//                     if time == nil { return }
//                     let date = Date(timeIntervalSince1970: TimeInterval(time!))
//                     let price = Price(timestamp: date, price: Double(latestPrice.price) / 1e9)
//                     DispatchQueue.main.async {
//                         print(price)
//                         self.prices.append(price)
//                     }
//                 }
//            case .failure(let error):
//                print(error)
//          }
//        }
    }
    
    func startPriceUpdates() {
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//            Task {
//                try await self?.fetchLatestPrice()
//                nil
//            }
//        }
    }
    
    override func handleBuy(buyAmountUSD: CGFloat) -> Bool {
        // Implement buy logic
        return false
    }
    
    override func handleSell() {
        // Implement sell logic
    }
    
    deinit {
        timer?.invalidate()
        cancellables.forEach { $0.cancel() }
    }
}
