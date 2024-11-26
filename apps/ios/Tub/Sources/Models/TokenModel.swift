import Apollo
import CodexAPI
import Combine
import SwiftUI
import TubAPI

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
    private var candleSubscription: Timer?

    private var latestPrice: Double?
    private var priceUpdateTimer: Timer?

    deinit {
        priceUpdateTimer?.invalidate()
        priceUpdateTimer = nil
        // Clean up subscriptions when the object is deallocated
        priceSubscription?.cancel()
        candleSubscription?.invalidate()
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
                // Add a retry mechanism with delay
                var attempts = 0
                let maxAttempts = 3

                while attempts < maxAttempts {
                    // Try fetching initial data
                    let prices = await fetchInitialPrices()
                    let candles = await fetchInitialCandles()

                    // Check if we got valid data
                    if !prices.isEmpty && !candles.isEmpty {
                        await MainActor.run {
                            self.prices = prices
                            self.candles = candles
                            self.lastPriceTimestamp = self.prices.last?.timestamp
                            self.latestPrice = self.prices.last?.priceUsd
                            self.isReady = true
                            self.calculatePriceChange()
                        }

                        // Set up subscriptions only after successful data fetch
                        await subscribeToTokenPrices()
                        await subscribeToCandles()
                        try await fetchUniqueHolders()
                        break
                    }

                    attempts += 1
                    if attempts < maxAttempts {
                        try await Task.sleep(nanoseconds: UInt64(1_000_000_000))  // 1 second delay
                    }
                }

                if attempts == maxAttempts {
                    print("Failed to fetch initial data after \(maxAttempts) attempts")
                    await MainActor.run {
                        self.isReady = false
                    }
                }
            }
            catch {
                print("Error fetching initial data: \(error)")
                await MainActor.run {
                    self.isReady = false
                }
            }
        }
    }

    private func fetchInitialPrices() async -> [Price] {
        let client = await CodexNetwork.shared.apolloClient
        let now = Int(Date().timeIntervalSince1970)
        let startTime = now - Int(Timespan.live.seconds)

        // Calculate number of intervals needed
        let numIntervals = Int(ceil(Timespan.live.seconds / PRICE_UPDATE_INTERVAL))
        // Create array of timestamps we need to fetch
        let timestamps = (0..<numIntervals).map { i in
            startTime + Int(Double(i) * PRICE_UPDATE_INTERVAL)
        }

        // Fetch all prices concurrently and collect them in order
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
                        return try await withCheckedThrowingContinuation { continuation in
                            client.fetch(query: query) { result in
                                switch result {
                                case .success(let response):
                                    if let prices = response.data?.getTokenPrices,
                                        let firstPrice = prices.first,
                                        let price = firstPrice?.priceUsd
                                    {
                                        continuation.resume(
                                            returning: Price(
                                                timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                                                priceUsd: price
                                            )
                                        )
                                    }
                                    else {
                                        continuation.resume(returning: nil)
                                    }
                                case .failure(let error):
                                    print("Error fetching price at timestamp \(timestamp): \(error)")
                                    continuation.resume(returning: nil)
                                }
                            }
                        }
                    }
                    catch {
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
            return allPrices.sorted { $0.timestamp < $1.timestamp }
        }

        return prices
    }

    private func subscribeToTokenPrices() async {
        priceSubscription?.cancel()

        // Start the timer for regular price updates
        priceUpdateTimer?.invalidate()
        DispatchQueue.main.async {
            self.priceUpdateTimer = Timer.scheduledTimer(withTimeInterval: PRICE_UPDATE_INTERVAL, repeats: true) {
                [weak self] _ in
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
        priceSubscription = client.subscribe(
            subscription: SubTokenPricesSubscription(
                tokenAddress: tokenId
            )
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("GraphQL errors: \(errors)")
                    return
                }

                if let events = graphQLResult.data?.onTokenEventsCreated.events {
                    let swaps =
                        events
                        .filter { $0.eventType == .swap }
                        .sorted { $0.timestamp < $1.timestamp }

                    if let lastSwap = swaps.last {
                        let priceUsd =
                            lastSwap.quoteToken == .token0
                            ? lastSwap.token0PoolValueUsd ?? "0" : lastSwap.token1PoolValueUsd ?? "0"

                        self.latestPrice = Double(priceUsd) ?? 0.0
                    }
                }
            case .failure(let error):
                print("Error in price subscription: \(error.localizedDescription)")
            }
        }
    }

    private func fetchInitialCandles() async -> [CandleData] {
        let client = await CodexNetwork.shared.apolloClient
        let now = Int(Date().timeIntervalSince1970)
        let startTime = now - Int(Timespan.candles.seconds)

        return try! await withCheckedThrowingContinuation { continuation in
            client.fetch(
                query: GetTokenCandlesQuery(
                    from: startTime,
                    to: now,
                    symbol: token.pairId,
                    resolution: "1"
                )
            ) { result in
                switch result {
                case .success(let response):
                    var allCandles: [CandleData] = []
                    if let bars = response.data?.getBars {
                        for index in 0..<bars.t.count {
                            let timestamp = bars.t[index]
                            guard let open = bars.o[index],
                                let close = bars.c[index],
                                let high = bars.h[index],
                                let low = bars.l[index]
                            else { continue }

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
                    continuation.resume(returning: allCandles)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        } ?? [] as! [CandleData]
    }

    private func subscribeToCandles() async {
        candleSubscription?.invalidate()
        candleSubscription = nil

        // Create a timer that fetches candles every 2 seconds
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            candleSubscription = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }

                Task {
                    self.candles = await self.fetchInitialCandles()
                }
            }
        }
    }

    private func calculatePriceChange() {
        let latestPrice = prices.last?.priceUsd ?? 0
        let startTime = Date().addingTimeInterval(-selectedTimespan.seconds)
        let initialPriceUsd: Double

        // Find first price corresponding to the selected timespan
        if selectedTimespan == .live {
            initialPriceUsd =
                prices.first(where: { $0.timestamp >= startTime })?.priceUsd ?? prices.first?.priceUsd ?? 0
        }
        else {
            // Find the price within the candles data
            initialPriceUsd = candles.first(where: { $0.start >= startTime })?.close ?? prices.first?.priceUsd ?? 0
        }

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
            ("Unique holders", !isReady ? nil : formatLargeNumber(Double(token.uniqueHolders))),
        ]
    }

    private func fetchUniqueHolders() async throws {
        let client = await CodexNetwork.shared.apolloClient
        return try await withCheckedThrowingContinuation { continuation in
            client.fetch(
                query: GetUniqueHoldersQuery(
                    pairId: "\(tokenId):\(NETWORK_FILTER)"
                )
            ) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: TubError.unknown)
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
