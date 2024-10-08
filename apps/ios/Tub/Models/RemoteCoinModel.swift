import SwiftUI
import Apollo
import TubAPI
import Combine

class RemoteCoinModel: BaseCoinModel {
    override init(tokenId: String) {
        super.init(tokenId: tokenId)
        Task {
            await fetchInitialData()
            subscribeToLatestPrice()
        }
    }
    
    private lazy var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private func fetchInitialData() async {
        do {
            try await fetchTokenDetails()
            self.loading = false
        } catch {
            print("Error fetching initial data: \(error)")
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
    
    private func subscribeToLatestPrice() {
        let _ = Network.shared.apollo.subscribe(subscription: GetLatestTokenPriceSubscription(tokenId: self.tokenId)) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    if let history = graphQLResult.data?.token_price_history.first {

                        if let date = self.formatDate(history.created_at) {
                            let newPrice = Price(timestamp: date, price: Double(history.price) / 1e9)
                            self.prices.append(newPrice)
                        } else {
                            print("Failed to parse date: \(history.created_at)")
                        }
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> Date? {
        let pattern = #"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\.(\d{6})"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: dateString, options: [], range: NSRange(dateString.startIndex..., in: dateString)) else {
            return nil
        }
        
        let dateRange = Range(match.range(at: 1), in: dateString)!
        let millisRange = Range(match.range(at: 2), in: dateString)!
        
        let datePart = String(dateString[dateRange])
        let millisPart = String(dateString[millisRange].prefix(3))
        
        return iso8601Formatter.date(from: datePart + "." + millisPart + "Z")
    }

    override func handleBuy(buyAmountUSD: CGFloat) -> Bool {
        // Implement buy logic
        return false
    }
    
    override func handleSell() {
        // Implement sell logic
    }
}

