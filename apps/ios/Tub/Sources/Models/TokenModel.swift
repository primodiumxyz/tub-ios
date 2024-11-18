import Apollo
import Combine
import SwiftUI
import TubAPI
import CodexAPI

class TokenModel: ObservableObject {
    var tokenId: String = ""
    var walletAddress: String = ""
    
    @Published var token: Token = Token(
        id: "",
        name: "COIN",
        symbol: "SYMBOL",
        description: "DESCRIPTION",
        imageUri: "",
        liquidity: 0.0,
        marketCap: 0.0,
        volume: 0.0,
        pairId: "",
        socials: (discord: "", instagram: "", telegram: "", twitter: "", website: ""),
        uniqueHolders: 0
    )
    @Published var loading = true
    @Published var balanceLamps: Int = 0
    
    @Published var purchaseData : PurchaseData? = nil
    
    @Published var prices: [Price] = []
    @Published var candles: [CandleData] = []
    @Published var priceChange: (amountUsd: Double, percentage: Double) = (0, 0)

    @Published var timeframeSecs: Double = 90
    @Published var currentTimeframe: Timespan = .live
    private var lastPriceTimestamp: Date?
 
    private var latestPriceSubscription: Apollo.Cancellable?
    private var tokenBalanceSubscription: Apollo.Cancellable?
    private var priceSubscription: Apollo.Cancellable?
    private var candleSubscription: Apollo.Cancellable?
    
    @Published var livePrices: [Price] = []
    @Published var candleData: [CandleData] = []
    @Published var activeView: Timespan = .live
    
    deinit {
        // Clean up subscriptions when the object is deallocated
        latestPriceSubscription?.cancel()
        tokenBalanceSubscription?.cancel()
        priceSubscription?.cancel()
        candleSubscription?.cancel()
    }
    
    init(walletAddress: String, token: Token? = nil) {
        self.walletAddress = walletAddress
        if let token = token {
            self.initialize(with: token)
        }
    }
    
    func initialize(with newToken: Token, timeframeSecs: Double = 90) {
        // Cancel existing subscriptions
        latestPriceSubscription?.cancel()
        tokenBalanceSubscription?.cancel()
        priceSubscription?.cancel()
        candleSubscription?.cancel()

        // Reset properties
        self.tokenId = newToken.id
        self.token = newToken
        self.loading = true
        self.livePrices = []
        self.candleData = []
        self.priceChange = (0, 0)
        self.balanceLamps = 0
        self.timeframeSecs = timeframeSecs

        Task {
            do {
                try await fetchTokenDetails()
                try await fetchUniqueHolders()
                
                // Fetch both types of data
                try await fetchInitialPrices(self.timeframeSecs)
                try await fetchInitialCandles()
                
                // Subscribe to both updates
                subscribeToTokenPrices()
                subscribeToCandles()
            } catch {
                print("Error fetching initial data: \(error)")
            }
            
            subscribeToTokenBalance()
        }
    }
    
    func fetchInitialPrices(_ timeframeSecs: Double) async throws {
        let now = Int(Date().timeIntervalSince1970)
        let batchSize = 25
        let numBatches = Int(ceil(timeframeSecs / Double(batchSize)))
        var allPrices: [Price] = []
        
        for i in 0..<numBatches {
            let batchChunkSize = min(batchSize, Int(timeframeSecs) - (i * batchSize))
            let inputs = (0..<batchChunkSize).map { index -> GetPriceInput in
                let timestamp = now - Int(timeframeSecs) + (i * batchSize + index)
                return GetPriceInput(
                    address: tokenId,
                    networkId: NETWORK_FILTER,
                    timestamp: .some(timestamp)
                )
            }
            
            let query = GetTokenPricesQuery(inputs: inputs)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                CodexNetwork.shared.apollo.fetch(query: query) { result in
                    switch result {
                    case .success(let response):
                        if let prices = response.data?.getTokenPrices {
                            let batchPrices = prices.compactMap { price -> Price? in
                                guard let timestamp = price?.timestamp,
                                      let priceUsd = price?.priceUsd else { return nil }
                                return Price(
                                    timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                                    priceUsd: priceUsd
                                )
                            }
                            allPrices.append(contentsOf: batchPrices)
                        }
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.prices = allPrices
                .sorted { $0.timestamp < $1.timestamp }
                .reduce(into: [Price]()) { result, price in
                    if let lastPrice = result.last?.priceUsd, lastPrice == price.priceUsd {
                        return
                    }
                    result.append(price)
                }
            self.lastPriceTimestamp = self.prices.last?.timestamp
            self.loading = false
            self.calculatePriceChange()
        }
    }

    private func fetchTokenDetails() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            CodexNetwork.shared.apollo.fetch(query: GetTokenMetadataQuery(
                address: tokenId
            ), cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
                guard let self = self else {
                    let error = NSError(
                        domain: "TokenModel",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Self is nil"]
                    )
                    continuation.resume(throwing: error)
                    return
                }
                
                switch result {
                case .success(let response):
                    if let metadata = response.data?.token {
                        DispatchQueue.main.async {
                            self.token = Token(
                                id: self.tokenId,
                                name: self.token.name,
                                symbol: self.token.symbol,
                                description: metadata.info?.description,
                                imageUri: self.token.imageUri,
                                liquidity: self.token.liquidity,
                                marketCap: self.token.marketCap,
                                volume: self.token.volume,
                                pairId: self.token.pairId,
                                socials: (
                                    discord: metadata.socialLinks?.discord,
                                    instagram: metadata.socialLinks?.instagram,
                                    telegram: metadata.socialLinks?.telegram,
                                    twitter: metadata.socialLinks?.twitter,
                                    website: metadata.socialLinks?.website
                                ),
                                uniqueHolders: self.token.uniqueHolders
                            )
                        }
                        continuation.resume()
                    } else {
                        let error = NSError(
                            domain: "TokenModel",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Token not found"]
                        )
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
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

    func buyTokens(buyAmountLamps: Int, priceModel: SolPriceModel, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        if let price = self.prices.last?.priceUsd, price > 0 {
            let tokenAmount = Int(Double(buyAmountLamps) / Double(priceModel.usdToLamports(usd: price)) * 1e9)
            
            Network.shared.buyToken(tokenId: self.tokenId, amount: String(tokenAmount), tokenPrice: String(price)
            ) { result in
                switch result {
                case .success:
                    self.purchaseData = PurchaseData (
                        timestamp: Date(),
                        amount: buyAmountLamps,
                        priceUsd: price
                    )
                case .failure(let error):
                    print("Error buying tokens: \(error)")
                }
                completion(result)
            }
        }
    }
    
    func sellTokens(completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        Network.shared.sellToken(tokenId: self.tokenId, amount: String(self.balanceLamps), tokenPrice: String(self.prices.last?.priceUsd ?? 0)
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


    
    func updateHistoryInterval(_ timespan: Timespan) {
        self.activeView = timespan
        self.calculatePriceChange()
        
        if self.timeframeSecs < timespan.timeframeSecs {
            self.timeframeSecs = timespan.timeframeSecs
            Task {
                do {
                    if timespan == .live {
                        try await fetchInitialPrices(timeframeSecs)
                    } else {
                        try await fetchInitialCandles()
                    }
                } catch {
                    print("Error updating history interval: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func calculatePriceChange() {
        let latestPrice = prices.last?.priceUsd ?? 0
        
        // Get timestamp for start of current timeframe
        let startTime = Date().addingTimeInterval(-currentTimeframe.timeframeSecs)
        
        // Find first price after the start time
        let initialPriceUsd = prices.first(where: { $0.timestamp >= startTime })?.priceUsd ?? prices.first?.priceUsd ?? 0
        
        if latestPrice == 0 || initialPriceUsd == 0 {
            print("Error: Cannot calculate price change. Prices are not available.")
            return
        }
        
        let priceChangeUsd = latestPrice - initialPriceUsd
        let priceChangePercentage = Double(priceChangeUsd) / Double(initialPriceUsd) * 100
        
        DispatchQueue.main.async {
            self.priceChange = (priceChangeUsd, priceChangePercentage)
        }
    }

    func updateTokenDetails(from token: Token) {
        DispatchQueue.main.async {
            self.token.liquidity = token.liquidity
            self.token.marketCap = token.marketCap
            self.token.volume = token.volume
        }
    }

    func getTokenStats(priceModel: SolPriceModel) -> [(String, String)] {
        return [
            ("Market Cap", loading ? "..." : priceModel.formatPrice(usd: token.marketCap, formatLarge: true)),
            ("Volume (\((Int(RESOLUTION) ?? Int(60)) / 60)h)", loading ? "..." : priceModel.formatPrice(usd: token.volume, formatLarge: true)),
            ("Liquidity", loading ? "..." : priceModel.formatPrice(usd: token.liquidity, formatLarge: true)),
            ("Unique holders", loading ? "..." : formatLargeNumber(Double(token.uniqueHolders)))
        ]
    }

    private func subscribeToTokenPrices() {
        priceSubscription?.cancel()
        
        priceSubscription = CodexNetwork.shared.apollo.subscribe(subscription: SubTokenPricesSubscription(
            tokenAddress: tokenId
        )) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let graphQLResult):
                print(graphQLResult)
                if let errors = graphQLResult.errors {
                    print("GraphQL errors: \(errors)")
                    return
                }
                
                if let events = graphQLResult.data?.onTokenEventsCreated.events {
                    let swaps = events
                        .filter { $0.eventType == .swap }
                        .sorted { $0.timestamp < $1.timestamp }
                    for swap in swaps {
                        if let lastTimestamp = self.lastPriceTimestamp?.timeIntervalSince1970,
                           Double(swap.timestamp) <= lastTimestamp {
                            continue
                        }
                        
                        let priceUsd = swap.quoteToken == .token0 ?
                            swap.token0PoolValueUsd ?? "0" : swap.token1PoolValueUsd ?? "0"
                        
                        let newPrice = Price(
                            timestamp: Date(timeIntervalSince1970: TimeInterval(swap.timestamp)),
                            priceUsd: Double(priceUsd) ?? 0.0
                        )
                        
                        DispatchQueue.main.async {
                            self.prices.append(newPrice)
                            self.lastPriceTimestamp = newPrice.timestamp
                            self.calculatePriceChange()
                        }
                    }
                }
            case .failure(let error):
                print("Error in price subscription: \(error.localizedDescription)")
            }
        }
    }

    private func fetchInitialCandles() async throws {
        let now = Int(Date().timeIntervalSince1970)
        let thirtyMinutesAgo = now - (30 * 60)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CodexNetwork.shared.apollo.fetch(query: GetTokenCandlesQuery(
                from: thirtyMinutesAgo,
                to: now,
                symbol: token.pairId,
                resolution: "1"
            )) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "TokenModel", code: 0))
                    return
                }
                
                switch result {
                case .success(let response):
                    if let bars = response.data?.getBars {
                        DispatchQueue.main.async {
                            self.candles = zip(0..<bars.t.count, bars.t).compactMap { index, timestamp in
                                guard let timestamp = .some(timestamp),
                                      let open = bars.o[index],
                                      let close = bars.c[index],
                                      let high = bars.h[index],
                                      let low = bars.l[index] else { return nil }
                                return CandleData(
                                    start: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                                    end: Date(timeIntervalSince1970: TimeInterval(timestamp) + 60),
                                    open: open,
                                    close: close,
                                    high: high,
                                    low: low,
                                    volume: bars.v[index]
                                )
                            }
                            self.loading = false
                        }
                    }
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func subscribeToCandles() {
        candleSubscription?.cancel()
        
        let subscription = SubTokenCandlesSubscription(pairId: token.pairId)
        
        candleSubscription = CodexNetwork.shared.apollo.subscribe(subscription: subscription) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let graphQLResult):
                if let newCandle = graphQLResult.data?.onBarsUpdated?.aggregates.r1?.token {
                    let candleData = CandleData(
                        start: Date(timeIntervalSince1970: TimeInterval(newCandle.t)),
                        end: Date(timeIntervalSince1970: TimeInterval(newCandle.t) + 60),
                        open: newCandle.o,
                        close: newCandle.c,
                        high: newCandle.h,
                        low: newCandle.l,
                        volume: newCandle.v
                    )
                    
                    DispatchQueue.main.async {
                        if let index = self.candles.firstIndex(where: { $0.start == candleData.start }) {
                            self.candles[index] = candleData
                        } else {
                            self.candles.append(candleData)
                        }
                    }
                }
            case .failure(let error):
                print("Error in candle subscription: \(error.localizedDescription)")
            }
        }
    }

    private func fetchUniqueHolders() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            CodexNetwork.shared.apollo.fetch(query: GetUniqueHoldersQuery(
                pairId: "\(tokenId):\(NETWORK_FILTER)"
            )) { [weak self] result in
                guard let self = self else {
                    let error = NSError(
                        domain: "TokenModel",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Self is nil"]
                    )
                    continuation.resume(throwing: error)
                    return
                }
                
                switch result {
                case .success(let response):
                    if let holders = response.data?.holders.count {
                        DispatchQueue.main.async {
                            self.token.uniqueHolders = holders
                        }
                    }
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
