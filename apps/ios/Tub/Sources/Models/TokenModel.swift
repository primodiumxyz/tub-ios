import Apollo
import Combine
import SwiftUI
import TubAPI

class TokenModel: ObservableObject {
    var tokenId: String = ""
    var userId: String = ""
    
    @Published var token: Token = Token(id: "", name: "COIN", symbol: "SYMBOL", mint: "", decimals: 6, imageUri: "")
    @Published var loading = true
    @Published var balance: Int = 0
    
    
    @Published var amountBoughtLamps: Int = 0
    @Published var purchaseTime : Date? = nil
    
    @Published var prices: [Price] = []
    
    private var latestPriceSubscription: Apollo.Cancellable?
    private var tokenBalanceSubscription: Apollo.Cancellable?
    
    @Published var priceChange: (amountLamps: Int, percentage: Double) = (0, 0)
    
    init(userId: String, tokenId: String? = nil) {
        self.userId = userId
        if tokenId != nil {
            self.initialize(with: tokenId!)
        }
    }
    
    private func fetchInitialData() async {
        do {
            try await fetchTokenDetails()
            //            self.loading = false
        } catch {
            print("Error fetching initial data: \(error)")
        }
    }
    
    
    private func fetchTokenDetails() async throws {
        let query = GetTokenDataQuery(tokenId: tokenId)
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query) { [weak self] result in
                guard let self = self else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "TokenModel", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
                switch result {
                case .success(let response):
                    if let token = response.data?.token.first(where: { $0.id == self.tokenId }) {
                        DispatchQueue.main.async {
                            self.token = Token(id: token.id, name: token.name, symbol: token.symbol, mint: token.mint ?? "", decimals: token.decimals, imageUri: token.uri)
                        }
                        continuation.resume()
                    } else {
                        continuation.resume(
                            throwing:
                                NSError(
                                    domain: "TokenModel",
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
    
    private func subscribeToLatestPrice(_ interval: Interval) {
        latestPriceSubscription?.cancel()
        let subscription = SubTokenPriceHistoryIntervalSubscription(token: self.tokenId, interval: .some(interval))
        
        latestPriceSubscription = Network.shared.apollo.subscribe(subscription: subscription) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let graphQLResult):
                if let priceHistory = graphQLResult.data?.token_price_history_offset {
                    DispatchQueue.main.async {
                        self.prices = priceHistory.compactMap { history in
                            if let date = self.formatDate(history.created_at) {
                                return Price(timestamp: date, price: history.price)
                            }
                            return nil
                        }
                        self.loading = false
                        self.calculatePriceChange()
                    }
                }
            case .failure(let error):
                print("Error in latest price subscription: \(error)")
            }
        }
    }
    
    private func subscribeToTokenBalance() {
        tokenBalanceSubscription?.cancel()
        
        tokenBalanceSubscription = Network.shared.apollo.subscribe(
            subscription: SubAccountTokenBalanceSubscription(
                account: Uuid(self.userId), token: self.tokenId)
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    self.balance =
                    graphQLResult.data?.balance.first?.value ?? 0
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private lazy var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private func formatDate(_ dateString: String) -> Date? {
        return iso8601Formatter.date(from: dateString)
    }
    func buyTokens(buyAmountLamps: Int, completion: ((Bool) -> Void)?) {
        if let price = self.prices.last?.price, price > 0 {
            let buyAmountToken = buyAmountLamps * Int(1e9) / price
            
            Network.shared.buyToken(
                accountId: self.userId, tokenId: self.tokenId, amount: String(buyAmountToken)
            ) { result in
                switch result {
                case .success:
                    self.amountBoughtLamps = buyAmountLamps
                    self.purchaseTime = Date()
                    completion?(true)
                case .failure(let error):
                    print("Error buying tokens: \(error)")
                    completion?(false)
                }
            }
        }
    }
    
    func sellTokens(completion: ((Bool) -> Void)?) {
        Network.shared.sellToken(
            accountId: self.userId, tokenId: self.tokenId, amount: String(self.balance)
        ) { result in
            switch result {
            case .success:
                self.purchaseTime = nil
                completion?(true)
            case .failure(let error):
                print("Error selling tokens: \(error)")
                completion?(false)
            }
        }
    }
    
    func initialize(with newTokenId: String) {
        // Cancel all existing subscriptions
        latestPriceSubscription?.cancel()
        tokenBalanceSubscription?.cancel()
        
        // Reset properties if necessary
        self.tokenId = newTokenId
        self.loading = true  // Reset loading state if needed
        self.prices = []
        self.priceChange = (0, 0)
        self.balance = 0
        
        // Re-run the initialization logic
        Task {
            await fetchInitialData()
            
            subscribeToLatestPrice("30s")
            subscribeToTokenBalance()
        }
    }
    
    func updateHistoryInterval(interval: Interval) {
        latestPriceSubscription?.cancel()
        self.prices = []
        self.loading = true
        subscribeToLatestPrice(interval)
    }
    
    private func calculatePriceChange() {
        let currentPrice = prices.last?.price ?? 0
        let initialPrice = prices.first?.price ?? 0
        if currentPrice == 0 || initialPrice == 0 {
            print("Error: Cannot calculate price change. Prices are not available.")
            return
        }
        
        let priceChangeAmount = currentPrice - initialPrice
        let priceChangePercentage = Double(priceChangeAmount) / Double(initialPrice) * 100
        
        DispatchQueue.main.async {
            self.priceChange = (priceChangeAmount, priceChangePercentage)
        }
    }
}
