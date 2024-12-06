import Apollo
import Combine
import SwiftUI
import TubAPI

let emptyToken = Token(
    id: "",
    name: "",
    symbol: "",
    description: "",
    imageUri: "",
    externalUrl: "",
    supply: 0,
    latestPriceUsd: 0,
    stats: IntervalStats(volumeUsd: 0, trades: 0, priceChangePct: 0),
    recentStats: IntervalStats(volumeUsd: 0, trades: 0, priceChangePct: 0)
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
    private var candleSubscription: Apollo.Cancellable?

    private var latestPrice: Double?
    private var priceUpdateTimer: Timer?
    private var preloaded = false
    private var initialized = false

    func preload(with newToken: Token, timeframeSecs: Double = CHART_INTERVAL) {
        cleanup()
        preloaded = true
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
            await self.subscribeToCandles(newToken.id)
            print("\(newToken.name) candle fetch took \(Date().timeIntervalSince(now)) seconds")
        }

        Task {
            do {
                try await retry(fetchCandles)
            }
            catch {
                print("Error fetching candles: \(error)")
            }
        }
    }

    func fetchInitialPrices(_ tokenId: String) async throws -> [Price] {
        let now = Date()
        let startTime = now.addingTimeInterval(-Timespan.live.seconds)
        
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: GetTokenPricesSinceQuery(
                token: tokenId,
                since: .some(iso8601Formatter.string(from: startTime))
            )) { result in
                switch result {
                case .success(let graphQLResult):
                    if let _ = graphQLResult.errors {
                        continuation.resume(throwing: TubError.unknown)
                        return
                    }

                    let prices = graphQLResult.data?.api_trade_history.map { trade in
                        Price(
                            timestamp: iso8601Formatter.date(from: trade.created_at) ?? now,
                            priceUsd: trade.token_price_usd
                        )
                    } ?? []
                    continuation.resume(returning: prices)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func subscribeToTokenPrices(_ tokenId: String) async {
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

        let now = Date()
        priceSubscription = Network.shared.apollo.subscribe(
            subscription: SubTokenPricesSinceSubscription(
                token: tokenId,
                since: .some(iso8601Formatter.string(from: now))
            )
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let graphQLResult):
                if let _ = graphQLResult.errors {
                    return
                }

                if let trades = graphQLResult.data?.api_trade_history,
                   let lastTrade = trades.last {
                    Task { @MainActor in
                        self.latestPrice = lastTrade.token_price_usd
                    }
                }
            case .failure(let error):
                print("Error in price subscription: \(error.localizedDescription)")
            }
        }
    }

    private func subscribeToCandles(_ tokenId: String) async {
        candleSubscription?.cancel()

        let now = Date()
        let since = now.addingTimeInterval(-Timespan.candles.seconds)
        candleSubscription = Network.shared.apollo.subscribe(
            subscription: SubTokenCandlesSubscription(
                token: tokenId,
                since: .some(iso8601Formatter.string(from: since)),
                candle_interval: .some("1m")
            )
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let graphQLResult):
                if let candles = graphQLResult.data?.token_trade_history_candles {
                    let updatedCandles = candles.map { candle in
                        CandleData(
                            start: iso8601FormatterNoFractional.date(from: candle.bucket) ?? now,
                            end: (iso8601FormatterNoFractional.date(from: candle.bucket) ?? now).addingTimeInterval(60),
                            open: candle.open_price_usd,
                            close: candle.close_price_usd,
                            high: candle.high_price_usd,
                            low: candle.low_price_usd,
                            volume: candle.volume_usd
                        )
                    }
                    
                    Task { @MainActor in
                        self.candles = updatedCandles
                    }
                }
            case .failure(let error):
                print("Error in candle subscription: \(error.localizedDescription)")
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

    func cleanup() {
        priceUpdateTimer?.invalidate()
        priceUpdateTimer = nil
        // Clean up subscriptions when the object is deallocated
        priceSubscription?.cancel()
        candleSubscription?.cancel()

    }

    deinit {
        cleanup()
    }

}
