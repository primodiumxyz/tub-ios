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
    @Published var activeView: Timespan?
    @Published var isReady = false

    @Published var prices: [Price] = []
    @Published var candles: [CandleData] = []
    @Published var priceChange: (amountUsd: Double, percentage: Double) = (0, 0)

    @Published var timeframeSecs: Double = CHART_INTERVAL
    @Published var currentTimeframe: Timespan = .live
    @Published var loadFailed = false
    @Published var animate = false

    private var lastPriceTimestamp: Date?

    private var priceSubscription: Apollo.Cancellable?
    private var candleSubscription: Apollo.Cancellable?

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
            self.timeframeSecs = timeframeSecs
        }
        Task(priority: .userInitiated) {
            do {
                // Fetch both types of data
                try await fetchInitialPrices(newToken.id, timeframeSecs: self.timeframeSecs)
                subscribeToTokenPrices(newToken.id)
                print("\(newToken.name) price fetch took \(Date().timeIntervalSince(now)) seconds")
                // Move final status update to main thread
                await MainActor.run {
                    self.isReady = true
                }
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
        Task { @MainActor in
            self.animate = true
        }
        if initialized { return }
        initialized = true
        if !self.preloaded {
            Task {
                self.preload(with: newToken, timeframeSecs: timeframeSecs)
            }
        }

        Task {
            do {
                try await self.fetchInitialCandles(newToken.pairId)
                await self.subscribeToCandles(newToken.pairId)
                print("\(newToken.name) candle fetch took \(Date().timeIntervalSince(now)) seconds")
            }
            catch {
                await MainActor.run {
                    self.loadFailed = true
                }
            }
        }

        Task(priority: .background) {
            do {
                try await self.fetchUniqueHolders()
                print("\(newToken.name) unique holders fetch took \(Date().timeIntervalSince(now)) seconds")
            }
            catch {
                print("Error fetching unique holders: \(error)")
            }
        }
    }

    func fetchInitialPrices(_ tokenId: String, timeframeSecs: Double = 30 * 60) async throws {
        let client = await CodexNetwork.shared.apolloClient
        let now = Int(Date().timeIntervalSince1970)
        let startTime = now - Int(timeframeSecs)

        // Use a fixed number of intervals
        let NUM_PRICE_INTERVALS = 60  // Constant number of intervals to change
        let intervalSize = timeframeSecs / Double(NUM_PRICE_INTERVALS)

        // Create array of timestamps we need to fetch
        let timestamps = (0..<NUM_PRICE_INTERVALS).map { i in
            startTime + Int(Double(i) * intervalSize)
        }

        // Fetch all prices and collect them in order
        let prices = await withTaskGroup(of: Price?.self) { group in
            for timestamp in timestamps {
                group.addTask {
                    let input = GetPriceInput(
                        address: tokenId,
                        networkId: NETWORK_FILTER,
                        timestamp: .some(timestamp)
                    )

                    let query = GetTokenPricesQuery(inputs: [input])
                    do {
                        return try await withCheckedThrowingContinuation {
                            (continuation: CheckedContinuation<Price?, Error>) in
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
        let sortedPrices = prices.sorted { $0.timestamp < $1.timestamp }

        DispatchQueue.main.async {
            self.prices = sortedPrices
            self.lastPriceTimestamp = self.prices.last?.timestamp
            self.latestPrice = self.prices.last?.priceUsd
            self.isReady = true
            self.calculatePriceChange()
        }
    }

    private func subscribeToTokenPrices(_ tokenId: String) {
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

        // Subscribe to real-time price updates
        priceSubscription = CodexNetwork.shared.apollo.subscribe(
            subscription: SubTokenPricesSubscription(
                tokenAddress: tokenId
            )
        ) { [weak self] result in
            guard let self else {
                return
            }

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

    private func fetchInitialCandles(_ pairId: String) async throws {
        let client = await CodexNetwork.shared.apolloClient
        let now = Int(Date().timeIntervalSince1970)
        let thirtyMinutesAgo = now - (30 * 60)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            client.fetch(
                query: GetTokenCandlesQuery(
                    from: thirtyMinutesAgo,
                    to: now,
                    symbol: pairId,
                    resolution: "1"
                )
            ) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: TubError.unknown)
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
                                    let low = bars.l[index]
                                else { return nil }
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
                        }
                    }
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func subscribeToCandles(_ pairId: String) async {
        candleSubscription?.cancel()
        candleSubscription = nil

        //        let client = await CodexNetwork.shared.apolloClient
        //        let subscription = SubTokenCandlesSubscription(pairId: pairId)
        //
        //        candleSubscription = client.subscribe(subscription: subscription) { [weak self] result in
        //            guard let self = self else { return }
        //            switch result {
        //            case .success(let graphQLResult):
        //                if let newCandle = graphQLResult.data?.onBarsUpdated?.aggregates.r1?.token {
        //                    let candleData = CandleData(
        //                        start: Date(timeIntervalSince1970: TimeInterval(newCandle.t)),
        //                        end: Date(timeIntervalSince1970: TimeInterval(newCandle.t) + 60),
        //                        open: newCandle.o,
        //                        close: newCandle.c,
        //                        high: max(newCandle.h, newCandle.c),
        //                        low: min(newCandle.l, newCandle.c),
        //                        volume: newCandle.v
        //                    )
        //                    DispatchQueue.main.async {
        //                        self.candles.append(candleData)
        //                        if let index = self.candles.firstIndex(where: { $0.start == candleData.start }) {
        //                            var updatedCandle = self.candles[index]
        //                            updatedCandle.close = candleData.close
        //                            updatedCandle.high = max(updatedCandle.high, candleData.close)
        //                            updatedCandle.low = min(updatedCandle.low, candleData.close)
        //                            updatedCandle.volume = candleData.volume
        //                            self.candles[index] = updatedCandle
        //                        } else {
        //                            self.candles.sort { $0.start < $1.start }
        //                        }
        //
        //                        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        //                        self.candles.removeAll { $0.start < thirtyMinutesAgo }
        //                    }
        //                }
        //            case .failure(let error):
        //                print("Error in candle subscription: \(error.localizedDescription)")
        //            }
        //        }
    }

    func updateHistoryInterval(_ timespan: Timespan) {
        self.calculatePriceChange()
        self.timeframeSecs = timespan.timeframeSecs
    }

    private func calculatePriceChange() {
        let latestPrice = prices.last?.priceUsd ?? 0

        // Get timestamp for start of current timeframe
        let startTime = Date().addingTimeInterval(-currentTimeframe.timeframeSecs)

        // Find first price after the start time
        let initialPriceUsd =
            prices.first(where: { $0.timestamp >= startTime })?.priceUsd ?? prices.first?.priceUsd ?? 0

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

    private func fetchUniqueHolders() async throws {
        let client = await CodexNetwork.shared.apolloClient
        return try await withCheckedThrowingContinuation { continuation in
            client.fetch(
                query: GetUniqueHoldersQuery(
                    pairId: "\(self.token.id):\(NETWORK_FILTER)"
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

    func stopAnimation() {
        DispatchQueue.main.async {
            self.animate = false
        }
    }

    func cleanup() {
        priceUpdateTimer?.invalidate()
        priceUpdateTimer = nil
        // Clean up subscriptions when the object is deallocated
        priceSubscription?.cancel()
        candleSubscription?.cancel()
        candleSubscription = nil

    }

    deinit {
        cleanup()
    }

}
