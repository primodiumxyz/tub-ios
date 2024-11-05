import Apollo
import Combine
import SwiftUI
import TubAPI

class TokenModel: ObservableObject {
    var tokenId: String = ""
    var walletAddress: String = ""
    
    var errorHandler: ErrorHandler? = nil
    @Published var token: Token = Token(id: "", name: "COIN", symbol: "SYMBOL", mint: "", decimals: 6, imageUri: "")
    @Published var loading = true
    @Published var balanceLamps: Int = 0
    
    @Published var amountBoughtLamps: Int = 0
    @Published var purchaseTime : Date? = nil
    
    @Published var prices: [Price] = []
    @Published var priceChange: (amountLamps: Int, percentage: Double) = (0, 0)
    @Published var priceRef: Price?
    
    private var lastPriceTimestamp: Date?

    private var timeframeSecs: Double = 30 * 60 
    private var latestPriceSubscription: Apollo.Cancellable?
    private var tokenBalanceSubscription: Apollo.Cancellable?
    
    
    init(walletAddress: String, tokenId: String? = nil) {
        self.walletAddress = walletAddress
        if tokenId != nil {
            self.initialize(with: tokenId!)
        }
    }
    
    func initialize(with newTokenId: String, timeframeSecs: Double = 30 * 60) {
        // Cancel all existing subscriptions
        latestPriceSubscription?.cancel()
        tokenBalanceSubscription?.cancel()

        // Reset properties if necessary
        self.tokenId = newTokenId
        self.loading = true  // Reset loading state if needed
        self.prices = []
        self.priceChange = (0, 0)
        self.balanceLamps = 0
        self.priceRef = nil

        // Re-run the initialization logic
        Task {
            self.timeframeSecs = timeframeSecs ?? 30 * 60
            await fetchInitialData(self.timeframeSecs)
            
            subscribeToLatestPrice()
            subscribeToTokenBalance()
        }
    }
    
    private func fetchInitialData(_ timeframeSecs: Double) async {
        do {
            try await fetchTokenDetails()
            try await fetchInitialPrices(timeframeSecs)
            // self.loading = false
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
                            self.token = Token(id: token.id, name: token.name, symbol: token.symbol, mint: token.mint ?? "", decimals: token.decimals ?? 6, imageUri: token.uri)
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

    private func fetchInitialPrices(_ timeframeSecs: Double) async throws {
        let since = Date().addingTimeInterval(-timeframeSecs).ISO8601Format()
        
        let query = GetTokenPriceHistorySinceQuery(tokenId: Uuid(tokenId), since: since)
        
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "TokenModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }

                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.prices = response.data?.token_price_history.compactMap { history in
                            if let date = formatDateString(history.created_at) {
                                return Price(timestamp: date, price: Int(history.price) ?? 0)
                            }
                            return nil
                        } ?? []
                        self.lastPriceTimestamp = self.prices.last?.timestamp
                        // Find the price ref the closest to 30s ago
                        self.priceRef = self.prices.min { a, b in
                            let timeframeStart = Date().addingTimeInterval(-30)
                            return abs(a.timestamp.timeIntervalSince(timeframeStart)) < 
                                   abs(b.timestamp.timeIntervalSince(timeframeStart))
                        }
                        self.loading = false
                        self.calculatePriceChange()
                    }
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func subscribeToLatestPrice() {
        latestPriceSubscription?.cancel()
        let subscription = SubLatestTokenPriceSubscription(tokenId: Uuid(self.tokenId))
        
        latestPriceSubscription = Network.shared.apollo.subscribe(subscription: subscription) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let graphQLResult):
                if let priceHistory = graphQLResult.data?.token_price_history.first,
                   let date = formatDateString(priceHistory.created_at) {
                    DispatchQueue.main.async {
                        let newPrice = Price(timestamp: date, price: Int(priceHistory.price) ?? 0)
                        
                        if self.lastPriceTimestamp != date {
                            self.prices.append(newPrice)
                            self.lastPriceTimestamp = date
                            self.calculatePriceChange()
                        }
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
            subscription: SubWalletTokenBalanceSubscription(
                wallet: self.walletAddress, token: self.tokenId)
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    self.balanceLamps =
                    graphQLResult.data?.balance.first?.value ?? 0
                case .failure(let error):
                    print("Error updating token balance: \(error.localizedDescription)")
                }
            }
        }
    }

    func buyTokens(buyAmountLamps: Int, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        if let price = self.prices.last?.price, price > 0 {
            let tokenAmount = Int(Double(buyAmountLamps) / Double(price) * 1e9)
            print("token amount:", tokenAmount)
            
            Network.shared.buyToken(tokenId: self.tokenId, amount: String(tokenAmount)
            ) { result in
                switch result {
                case .success:
                    self.amountBoughtLamps = buyAmountLamps
                    self.purchaseTime = Date()
                case .failure(let error):
                    print("Error buying tokens: \(error)")
                }
                completion(result)
            }
        }
    }
    
    func sellTokens(completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        Network.shared.sellToken(tokenId: self.tokenId, amount: String(self.balanceLamps)
        ) { result in
            switch result {
            case .success:
                self.purchaseTime = nil
            case .failure(let error):
                print("Error selling tokens: \(error)")
            }
            completion(result)
        }
    }


    
    func updateHistoryTimeframe(_ _timeframeSecs: Double) {
        if _timeframeSecs <= self.timeframeSecs {
            return
        }
        self.timeframeSecs = _timeframeSecs

        latestPriceSubscription?.cancel()
        self.prices = []
        self.loading = true
        Task {
            await fetchInitialData(_timeframeSecs)
            subscribeToLatestPrice()
        }
    }
    
    private func calculatePriceChange() {
        let latestPrice = prices.last?.price ?? 0
        let initialPrice = priceRef?.price ?? self.prices.first?.price ?? 0
        
        if latestPrice == 0 || initialPrice == 0 {
            print("Error: Cannot calculate price change. Prices are not available.")
            return
        }
        
        let priceChangeAmount = latestPrice - initialPrice
        let priceChangePercentage = Double(priceChangeAmount) / Double(initialPrice) * 100
        
        DispatchQueue.main.async {
            self.priceChange = (priceChangeAmount, priceChangePercentage)
        }
    }
}
