import Apollo
import Combine
import SwiftUI
import TubAPI
import CodexAPI

let emptyToken = Token(
    id: "",
    name: "",
    symbol: "",
    description: "",
    imageUri: "",
    liquidity: 0,
    marketCap: 0,
    volume: 0,
    pairId: "",
    socials: (discord: nil, instagram: nil, telegram: nil, twitter: nil, website: nil),
    uniqueHolders: 0
)

class TokenModel: ObservableObject {
    var tokenId: String = ""

    @Published var token: Token = emptyToken
    @Published var isReady = false

    @Published var prices: [Price] = []
    @Published var candles: [CandleData] = []
    @Published var priceChange: (amountUsd: Double, percentage: Double) = (0, 0)
    
    @Published var selectedTimespan: Timespan = .live

    private var lastPriceTimestamp: Date?
    
    private var priceSubscription: Apollo.Cancellable?
    private var candleSubscription: Apollo.Cancellable?
    
    deinit {
        // Clean up subscriptions when the object is deallocated
        priceSubscription?.cancel()
        candleSubscription?.cancel()
        candleSubscription = nil
    }

    init(token: Token? = nil) {
        if let token = token {
            self.initialize(with: token)
        }
    }
    
    func initialize(with newToken: Token) {
        DispatchQueue.main.async {
            self.tokenId = newToken.id
            self.token = newToken
            self.isReady = false
            self.prices = []
            self.candles = []
            self.priceChange = (0, 0)
        }

        Task {
            do {
                try await fetchUniqueHolders()
                
                // Fetch both types of data
                if (selectedTimespan == .live) {
                    await fetchInitialPrices()
                    await fetchInitialCandles()
                } else {
                    await fetchInitialCandles()
                    await fetchInitialPrices()
                }
                
                // Move final status update to main thread
                DispatchQueue.main.async {
                    self.isReady = true
                }
                
                // Subscribe to both updates
                if (selectedTimespan == .live) {
                    await subscribeToTokenPrices()
                    await subscribeToCandles()
                } else {
                    await subscribeToCandles()
                    await subscribeToTokenPrices()
                }
            } catch {
                print("Error fetching initial data: \(error)")
                DispatchQueue.main.async {
                    self.isReady = false
                }
            }
        }
    }

    func fetchInitialPrices() async {
        let client = await CodexNetwork.shared.apolloClient
        let now = Int(Date().timeIntervalSince1970)
        let batchSize = 25
        let numBatches = Int(ceil(CHART_INTERVAL / Double(batchSize)))
        
        func getTokenPrices() async -> [Price] {
            var allPrices: [Price] = []
            for i in 0..<numBatches {
                let batchChunkSize = min(batchSize, Int(CHART_INTERVAL) - (i * batchSize))
                let inputs = (0..<batchChunkSize).map { index -> GetPriceInput in
                    let timestamp = now - Int(CHART_INTERVAL) + (i * batchSize + index)
                    return GetPriceInput(
                        address: tokenId,
                        networkId: NETWORK_FILTER,
                        timestamp: .some(timestamp)
                    )
                }
                
                let query = GetTokenPricesQuery(inputs: inputs)
                do {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        client.fetch(query: query) { result in
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
                } catch {
                    print(error)
                    }
                }
            return allPrices
        }
        
        let allPrices = await getTokenPrices()
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
            self.isReady = true
            self.calculatePriceChange()
        }
    }


    private func subscribeToTokenPrices() async {
        priceSubscription?.cancel()
        
        let client = await CodexNetwork.shared.apolloClient
        priceSubscription = client.subscribe(subscription: SubTokenPricesSubscription(
            tokenAddress: tokenId
        )) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let graphQLResult):
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

    private func fetchInitialCandles() async {
        let client = await CodexNetwork.shared.apolloClient
        let now = Int(Date().timeIntervalSince1970)
        let thirtyMinutesAgo = now - (30 * 60)
        
        func getTokenCandles() async -> [CandleData] {
            var allCandles: [CandleData] = []
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    client.fetch(query: GetTokenCandlesQuery(
                        from: thirtyMinutesAgo,
                        to: now,
                        symbol: token.pairId,
                        resolution: "1"
                    )) { result in
                        switch result {
                        case .success(let response):
                            if let bars = response.data?.getBars {
                                for index in 0..<bars.t.count {
                                    let timestamp = bars.t[index]
                                    guard let open = bars.o[index],
                                          let close = bars.c[index],
                                          let high = bars.h[index],
                                          let low = bars.l[index] else { continue }
                                    
                                    let candleData = CandleData(
                                        start: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                                        end: Date(timeIntervalSince1970: TimeInterval(timestamp) + 60),
                                        open: open,
                                        close: close,
                                        high: high,
                                        low: low,
                                        volume: bars.v[index]
                                    )
                                    allCandles.append(candleData)
                                }
                            }
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            } catch {
                print(error)
            }
            return allCandles
        }
        
        let allCandles = await getTokenCandles()
        DispatchQueue.main.async {
            self.candles = allCandles
            self.isReady = true
        }
    }

    private func subscribeToCandles() async {
        candleSubscription?.cancel()
        candleSubscription = nil
        
        let client = await CodexNetwork.shared.apolloClient
        // TODO: Disabled until Codex fixes; prices in the subscription are returned in SOL instead of USD, so instead we'll just query again in a timer
        // Create a timer that fetches candles every second
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
            
                Task {
                    await self.fetchInitialCandles()
                }
            }
        }
        
        // Store the timer as a Cancellable
        self.candleSubscription = AnyCancellable(timer)
    }

        // let subscription = SubTokenCandlesSubscription(pairId: token.pairId)
        
        // candleSubscription = client.subscribe(subscription: subscription) { [weak self] result in
        //     guard let self = self else { return }
        //     switch result {
        //     case .success(let graphQLResult):
        //         if let newCandle = graphQLResult.data?.onBarsUpdated?.aggregates.r1?.token {
        //             let candleData = CandleData(
        //                 start: Date(timeIntervalSince1970: TimeInterval(newCandle.t)),
        //                 end: Date(timeIntervalSince1970: TimeInterval(newCandle.t) + 60),
        //                 open: newCandle.o,
        //                 close: newCandle.c,
        //                 high: max(newCandle.h, newCandle.c),
        //                 low: min(newCandle.l, newCandle.c),
        //                 volume: newCandle.v
        //             )
        //             DispatchQueue.main.async {
        //                 self.candles.append(candleData)
        //                 if let index = self.candles.firstIndex(where: { $0.start == candleData.start }) {
        //                     var updatedCandle = self.candles[index]
        //                     updatedCandle.close = candleData.close
        //                     updatedCandle.high = max(updatedCandle.high, candleData.close)
        //                     updatedCandle.low = min(updatedCandle.low, candleData.close)
        //                     updatedCandle.volume = candleData.volume
        //                     self.candles[index] = updatedCandle
        //                 } else {
        //                     self.candles.sort { $0.start < $1.start }
        //                 }
                        
        //                 let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        //                 self.candles.removeAll { $0.start < thirtyMinutesAgo }
        //             }
        //         }
        //     case .failure(let error):
        //         print("Error in candle subscription: \(error.localizedDescription)")
        //     }
        // }
    }
    
    private func calculatePriceChange() {
        let latestPrice = prices.last?.priceUsd ?? 0
        
        // Get timestamp for start of current timeframe
        let startTime = Date().addingTimeInterval(-CHART_INTERVAL)
        
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

    func getTokenStats(priceModel: SolPriceModel) -> [(String, String?)] {
        return [
            ("Market Cap", !isReady ? nil : priceModel.formatPrice(usd: token.marketCap, formatLarge: true)),
            ("Volume (1h)", !isReady ? nil : priceModel.formatPrice(usd: token.volume, formatLarge: true)),
            ("Liquidity", !isReady ? nil : priceModel.formatPrice(usd: token.liquidity, formatLarge: true)),
            ("Unique holders", !isReady ? nil : formatLargeNumber(Double(token.uniqueHolders)))
        ]
    }

    private func fetchUniqueHolders() async throws {
        let client = await CodexNetwork.shared.apolloClient
        return try await withCheckedThrowingContinuation { continuation in
            client.fetch(query: GetUniqueHoldersQuery(
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
