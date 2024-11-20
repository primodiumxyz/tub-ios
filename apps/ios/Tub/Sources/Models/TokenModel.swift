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
    // private var candleSubscription: Apollo.Cancellable?
    private var candleSubscription: Timer?
    
    private var latestPrice: Double?
    private var priceUpdateTimer: Timer?
    
    deinit {
        priceUpdateTimer?.invalidate()
        priceUpdateTimer = nil
        // Clean up subscriptions when the object is deallocated
        priceSubscription?.cancel()
        // candleSubscription?.cancel()
        candleSubscription?.invalidate()
        candleSubscription = nil
    }
    
    init(token: Token? = nil, completion: (() -> Void)? = nil) {
        if let token = token {
            Task {
                await self.initialize(with: token)
                completion?()
            }
        }
    }
    
    func initialize(with newToken: Token) async {
        DispatchQueue.main.async {
            self.tokenId = newToken.id
            self.token = newToken
            self.isReady = false
            self.prices = []
            self.candles = []
            self.priceChange = (0, 0)
        }

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

    func fetchInitialPrices() async {
        let client = await CodexNetwork.shared.apolloClient
        let now = Int(Date().timeIntervalSince1970)
        let startTime = now - Int(CHART_INTERVAL)
        
        // Calculate number of intervals needed
        let numIntervals = Int(ceil(CHART_INTERVAL / PRICE_UPDATE_INTERVAL))
        
        // Create array of timestamps we need to fetch
        let timestamps = (0..<numIntervals).map { i in
            startTime + Int(Double(i) * PRICE_UPDATE_INTERVAL)
        }
        
        // Fetch all prices and collect them in order
        let prices = await withTaskGroup(of: Price?.self) { group in
            for timestamp in timestamps {
                group.addTask {
                    let input = GetPriceInput(
                        address: self.tokenId,
                        networkId: NETWORK_FILTER,
                        timestamp: .some(timestamp)
                    )
                    
                    let query = GetTokenPricesQuery(inputs: [input])
                    do {
                        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Price?, Error>) in
                            client.fetch(query: query) { result in
                                switch result {
                                case .success(let response):
                                    if let prices = response.data?.getTokenPrices,
                                       let firstPrice = prices.first,
                                       let price = firstPrice?.priceUsd {
                                        continuation.resume(returning: Price(
                                            timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                                            priceUsd: price
                                        ))
                                    } else {
                                        continuation.resume(returning: nil)
                                    }
                                case .failure(let error):
                                    print("Error fetching price at timestamp \(timestamp): \(error)")
                                    continuation.resume(returning: nil)
                                }
                            }
                        }
                    } catch {
                        print("Error fetching price at timestamp \(timestamp): \(error)")
                        return nil
                    }
                }
            }
            
            var allPrices: [Price] = []
            for await price in group {
                if let price = price {
                    allPrices.append(price)
                }
            }
            return allPrices
        }
        
        let sortedPrices = prices.sorted { $0.timestamp < $1.timestamp }
        
        DispatchQueue.main.async {
            self.prices = sortedPrices
            self.lastPriceTimestamp = self.prices.last?.timestamp
            self.latestPrice = self.prices.last?.priceUsd
            self.isReady = true
            self.calculatePriceChange()
        }
    }
    
    private func subscribeToTokenPrices() async {
        priceSubscription?.cancel()
        
        // Start the timer for regular price updates
        priceUpdateTimer?.invalidate()
        DispatchQueue.main.async {
            self.priceUpdateTimer = Timer.scheduledTimer(withTimeInterval: PRICE_UPDATE_INTERVAL, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                let now = Date()
                if let price = self.latestPrice {
                    // Add a new price point at each interval
                    let newPrice = Price(timestamp: now, priceUsd: price)
                    self.prices.append(newPrice)
                    self.lastPriceTimestamp = now
                    self.calculatePriceChange()
                }
            }
            
            // Make sure the timer is retained
            RunLoop.main.add(self.priceUpdateTimer!, forMode: .common)
        }
        
        let client = await CodexNetwork.shared.apolloClient
        // Subscribe to real-time price updates
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
                    
                    if let lastSwap = swaps.last {
                        let priceUsd = lastSwap.quoteToken == .token0 ?
                        lastSwap.token0PoolValueUsd ?? "0" : lastSwap.token1PoolValueUsd ?? "0"
                        
                        self.latestPrice = Double(priceUsd) ?? 0.0
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
        // candleSubscription?.cancel()
        candleSubscription?.invalidate()
        candleSubscription = nil
        
        let client = await CodexNetwork.shared.apolloClient

        // TODO: Disabled until Codex fixes; prices in the subscription are returned in SOL instead of USD, so instead we'll just query again in a timer
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

        // Create a timer that fetches candles every second
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.candleSubscription = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
            
                Task {
                    await self.fetchInitialCandles()
                }
            }
        }
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
