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
    @Published var token: Token = emptyToken
    @Published var isReady = false

    @Published var prices: [Price] = []
    @Published var candles: [CandleData] = []
    @Published var priceChange: (amountUsd: Double, percentage: Double) = (0, 0)

    @Published var selectedTimespan: Timespan = .live

    @Published var loadFailed = false
    private var lastPriceTimestamp: Date?

    private var priceSubscription: Apollo.Cancellable?
    private var candleSubscription: Timer?

    private var latestPrice: Double?
    private var priceUpdateTimer: Timer?
    private var preloaded = false
    private var initialized = false

    func preload(with newToken: Token, timeframeSecs: Double = CHART_INTERVAL) {
        cleanup()
        preloaded = true
        let now = Date()
        DispatchQueue.main.async {
            self.token = newToken
            self.isReady = false
            self.prices = []
            self.candles = []
            self.priceChange = (0, 0)
        }

        func fetchPrices() async throws {
            // Fetch both types of data
            let prices = try await fetchInitialPrices(newToken.id)
            if prices.isEmpty {
                throw TubError.emptyTokenList
            }
            await subscribeToTokenPrices(newToken.id)
            // Move final status update to main thread
            await MainActor.run {
                self.prices = prices
                self.isReady = true
                self.lastPriceTimestamp = self.prices.last?.timestamp
                self.latestPrice = self.prices.last?.priceUsd
                self.calculatePriceChange()
            }

        }

        Task(priority: .userInitiated) {
            do {
                try await retry(fetchPrices)
            }
            catch {
                print("Error fetching prices: \(error)")
                await MainActor.run {
                    self.loadFailed = true
                }
            }

        }

    }

    func initialize(with newToken: Token, timeframeSecs: Double = CHART_INTERVAL) {
        let now = Date()
        if initialized { return }
        initialized = true
        if !self.preloaded {
            Task {
                self.preload(with: newToken, timeframeSecs: timeframeSecs)
            }
        }

        func fetchCandles() async throws {
            let candles = await self.fetchInitialCandles(newToken.pairId)
            if candles.isEmpty {
                throw TubError.emptyTokenList
            }
            await self.subscribeToCandles(newToken.pairId)
            print("\(newToken.name) candle fetch took \(Date().timeIntervalSince(now)) seconds")
            await MainActor.run {
                self.candles = candles
            }
        }

        Task {
            do {
                try await retry(fetchCandles)
            }
            catch {
                print("Error fetching candles: \(error)")
            }
        }

        func fetchHolders() async throws {
            let holders = try await fetchUniqueHolders()
            await MainActor.run {
                self.token.uniqueHolders = holders
            }
        }

        Task(priority: .background) {
            do {
                try await retry(fetchHolders)
            }
            catch {
                print("Error fetching unique holders: \(error)")
            }
        }
    }

    func fetchInitialPrices(_ tokenId: String) async throws -> [Price] {
        let client = await CodexNetwork.shared.apolloClient
        let now = Int(Date().timeIntervalSince1970)
        let startTime = now - Int(Timespan.live.seconds)

        // Use a fixed number of intervals
        let NUM_PRICE_INTERVALS = 60  // Constant number of intervals to change
        let intervalSize = Timespan.live.seconds / Double(NUM_PRICE_INTERVALS)

        // Create array of timestamps we need to fetch
        let timestamps = (0..<NUM_PRICE_INTERVALS).map { i in
            startTime + Int(Double(i) * intervalSize)
        }

        // Fetch all prices concurrently and collect them in order
        let prices = await withTaskGroup(of: Price?.self) { group in
            for timestamp in timestamps {
                group.addTask {
                    let input = GetPriceInput(
                        address: self.token.id,
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

        if prices.count < 2 {
            throw TubError.networkFailure
        }
        return prices.sorted { $0.timestamp < $1.timestamp }

    }

    private func subscribeToTokenPrices(_ newTokenId: String) async {
        priceSubscription?.cancel()
        self.priceUpdateTimer?.invalidate()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.priceUpdateTimer = Timer.scheduledTimer(withTimeInterval: PRICE_UPDATE_INTERVAL, repeats: true) {
                [weak self] _ in
                guard let self else {
                    return
                }

                let now = Date()
                if let price = self.latestPrice {
                    // Add a new price point at each interval
                    let newPrice = Price(timestamp: now, priceUsd: price)
                    Task { @MainActor in
                        self.prices.append(newPrice)
                        self.lastPriceTimestamp = now
                    }
                    self.calculatePriceChange()
                }

            }

            // Make sure the timer is retained
            if let timer = self.priceUpdateTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }

        let client = await CodexNetwork.shared.apolloClient
        // Subscribe to real-time price updates
        priceSubscription = client.subscribe(
            subscription: SubTokenPricesSubscription(
                tokenAddress: newTokenId
            )
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let graphQLResult):
                if let _ = graphQLResult.errors {
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

                        Task { @MainActor in
                            self.latestPrice = Double(priceUsd) ?? 0.0
                        }
                    }
                }
            case .failure(let error):
                print("Error in price subscription: \(error.localizedDescription)")
            }
        }
    }

    private func fetchInitialCandles(_ pairId: String) async -> [CandleData] {
        let client = await CodexNetwork.shared.apolloClient
        let now = Int(Date().timeIntervalSince1970)
        let startTime = now - Int(Timespan.candles.seconds)

        return try! await withCheckedThrowingContinuation { continuation in
            client.fetch(
                query: GetTokenCandlesQuery(
                    from: startTime,
                    to: now,
                    symbol: pairId,
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

    private func subscribeToCandles(_ pairId: String) async {
        candleSubscription?.invalidate()
        candleSubscription = nil

        // Create a timer that fetches candles every 2 seconds
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            candleSubscription = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }

                Task {
                    self.candles = await self.fetchInitialCandles(pairId)
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

    func getTokenStats(priceModel: SolPriceModel) -> [(String, String?)] {
        return [
            ("Market Cap", !isReady ? nil : priceModel.formatPrice(usd: token.marketCap, formatLarge: true)),
            ("Volume (1h)", !isReady ? nil : priceModel.formatPrice(usd: token.volume, formatLarge: true)),
            ("Liquidity", !isReady ? nil : priceModel.formatPrice(usd: token.liquidity, formatLarge: true)),
            ("Unique holders", !isReady ? nil : formatLargeNumber(Double(token.uniqueHolders))),
        ]
    }

    private func fetchUniqueHolders() async throws -> Int {
        let client = await CodexNetwork.shared.apolloClient
        let holders: Int? = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Int?, Error>) in
            client.fetch(
                query: GetUniqueHoldersQuery(
                    pairId: "\(self.token.id):\(NETWORK_FILTER)"
                )
            ) { [weak self] result in
                guard let _ = self else {
                    continuation.resume(throwing: TubError.unknown)
                    return
                }

                switch result {
                case .success(let response):
                    continuation.resume(returning: response.data?.holders.count)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        if let holders {
            return holders
        }
        else {
            throw TubError.unknown
        }
    }

    func cleanup() {
        priceUpdateTimer?.invalidate()
        priceUpdateTimer = nil
        // Clean up subscriptions when the object is deallocated
        priceSubscription?.cancel()
        candleSubscription?.invalidate()
        candleSubscription = nil

    }

    deinit {
        cleanup()
    }

}
