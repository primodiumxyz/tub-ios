import Apollo
import Combine
import SwiftUI
import TubAPI

class TokenModel: ObservableObject {
    var tokenId: String = ""
    var walletAddress: String = ""
    @EnvironmentObject private var errorHandler: ErrorHandler
    
    @Published var token: Token = Token(
        id: "",
        mint: "",
        name: "COIN",
        symbol: "SYMBOL",
        description: "DESCRIPTION",
        supply: 0,
        decimals: 6,
        imageUri: "",
        volume: (0, FILTER_INTERVAL)
    )
    @Published var loading = true
    @Published var balanceLamps: Int = 0
    
    @Published var purchaseData : PurchaseData? = nil
    
    @Published var prices: [Price] = []
    @Published var priceChange: (amountLamps: Int, percentage: Double) = (0, 0)
    @Published var interval: Interval = CHART_INTERVAL
 
    private var latestPriceSubscription: Apollo.Cancellable?
    private var tokenBalanceSubscription: Apollo.Cancellable?
        
    init(walletAddress: String, tokenId: String? = nil) {
        self.walletAddress = walletAddress
        if tokenId != nil {
            self.initialize(with: tokenId!)
        }
    }
    
    func initialize(with newTokenId: String, interval: Interval = CHART_INTERVAL) {
        // Cancel all existing subscriptions
        latestPriceSubscription?.cancel()
        tokenBalanceSubscription?.cancel()

        // Reset properties if necessary
        self.tokenId = newTokenId
        self.loading = true  // Reset loading state if needed
        self.prices = []
        self.priceChange = (0, 0)
        self.balanceLamps = 0
        self.interval = interval

        // Re-run the initialization logic
        Task {
            do {
                try await fetchTokenDetails()
            } catch {
                print("Error fetching initial data: \(error)")
            }
            
            subscribeToLatestPrice()
            subscribeToTokenBalance()
        }
    }
    
    private func fetchTokenDetails() async throws {
        let query = GetTokenDataQuery(tokenId: tokenId)
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query) { [weak self] result in
                guard let self = self else {
                    let error = NSError(
                        domain: "TokenModel",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Self is nil"]
                    )
                    self?.errorHandler.show(error)
                    continuation.resume(throwing: error)
                    return
                }
                
                switch result {
                case .success(let response):
                    if let token = response.data?.token.first(where: { $0.id == self.tokenId }) {
                        DispatchQueue.main.async {
                            self.token = Token(
                                id: token.id,
                                mint: token.mint,
                                name: token.name,
                                symbol: token.symbol,
                                description: token.description,
                                supply: token.supply,
                                decimals: token.decimals,
                                imageUri: token.uri,
                                volume: (0, FILTER_INTERVAL)
                            )
                        }
                        continuation.resume()
                    } else {
                        let error = NSError(
                            domain: "TokenModel",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Token not found"]
                        )
                        errorHandler.show(error)
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    errorHandler.show(error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func subscribeToLatestPrice() {
        latestPriceSubscription?.cancel()
        let subscription = SubTokenPriceHistoryIntervalSubscription(token: Uuid(self.tokenId), interval: .some(self.interval))
        
        latestPriceSubscription = Network.shared.apollo.subscribe(subscription: subscription) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let graphQLResult):
                if let priceHistory = graphQLResult.data?.token_price_history_offset {
                    DispatchQueue.main.async {
                        self.prices = priceHistory.compactMap { history in
                            if let date = formatDateString(history.created_at) {
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
                    self.purchaseData = PurchaseData (
                        timestamp: Date(),
                        amount: buyAmountLamps,
                        price: price
                    )
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
                self.purchaseData = nil
            case .failure(let error):
                print("Error selling tokens: \(error)")
            }
            completion(result)
        }
    }


    
    func updateHistoryInterval(_ interval: Interval) {
        latestPriceSubscription?.cancel()
        self.prices = []
        self.loading = true
        self.interval = interval
        subscribeToLatestPrice()
    }
    
    private func calculatePriceChange() {
        let latestPrice = prices.last?.price ?? 0
        let initialPrice = self.prices.first?.price ?? 0
        
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

    func updateTokenDetails(from token: Token) {
        DispatchQueue.main.async {
            self.token = token
        }
    }

    func getTokenStats(priceModel: SolPriceModel) -> [(String, String)] {
        let currentPrice = prices.last?.price ?? 0
        let marketCap = Double(token.supply) / pow(10.0, Double(token.decimals)) * Double(currentPrice) // we're dividing first otherwise it will overflow...
        let supplyValue = Double(token.supply) / pow(10.0, Double(token.decimals))
        
        return [
            ("Market Cap", priceModel.formatPrice(lamports: Int(marketCap))),
            ("Volume (\(String(token.volume.interval)))", priceModel.formatPrice(lamports: token.volume.value, formatLarge: true)),
            ("Holders", "53.3K"), // TODO: Add holders data
            ("Supply", formatLargeNumber(supplyValue))
        ]
    }

    // Helper function to format large numbers
    private func formatLargeNumber(_ number: Double) -> String {
        if number >= 1_000_000_000 {
            return String(format: "%.1fB", number / 1_000_000_000)
        } else if number >= 1_000_000 {
            return String(format: "%.1fM", number / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", number / 1_000)
        } else {
            return String(format: "%.1f", number)
        }
    }
}
