import Apollo
import Combine
import SwiftUI
import TubAPI



class TokenModel: ObservableObject {
    @Published var tokenId: String = ""
    @Published var isReady = false

    @Published var prices: [Price] = []
    @Published var candles: [CandleData] = []
    @Published var priceChange: (amountUsd: Double, percentage: Double) = (0, 0)

    @Published var selectedTimespan: Timespan = .live

    @Published var loadFailed = false

    private var priceSubscription: Apollo.Cancellable?
    private var candleSubscription: Apollo.Cancellable?
    private var singleTokenDataSubscription: Apollo.Cancellable?

    private var preloaded = false
    private var initialized = false
    
    @Published var purchaseData: PurchaseData? 

    private var priceTimer: Timer? = nil

    private func fetchPurchaseData() async throws {
        if self.purchaseData != nil {
            return
        }
        
        guard let walletAddress = UserModel.shared.walletAddress else { return }
        
        let query = GetLatestTokenPurchaseQuery(wallet: walletAddress, mint: tokenId)
        let purchaseData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PurchaseData, Error>) in
            Network.shared.graphQL.fetch(query: query) {
                result in switch result {
                case .success(let response):
                    if let err = response.errors?.first?.message {
                        continuation.resume(throwing: TubError.serverError(reason:err))
                        return
                    }
                    guard let tx = response.data?.transactions.first, let timestamp = iso8601Formatter.date(from: tx.created_at) else {
                        continuation.resume(throwing: TubError.serverError(reason:"No purchases found"))
                        return
                    }
                    let purchaseData = PurchaseData(tokenId: tx.token_mint, timestamp: timestamp, amountToken: Int(tx.token_amount), priceUsd: tx.token_price_usd)
                    continuation.resume(returning: purchaseData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        
        await MainActor.run {
            self.purchaseData = purchaseData
        }
    }

    @MainActor
    func updatePrice(timestamp: Date, priceUsd: Double?) {
        guard let priceUsd, timestamp != self.prices.last?.timestamp else { return }
        self.prices.append(Price(timestamp: timestamp, priceUsd: priceUsd))
        let timespan = Timespan.live.seconds
        self.prices = self.prices.filter { $0.timestamp >= timestamp.addingTimeInterval(-timespan) }

        UserModel.shared.updateTokenPrice(mint: tokenId, priceUsd: priceUsd)
    }

    func getPrice(at timestamp: Date) -> Price? {
        return prices.first(where: { $0.timestamp <= timestamp }) ?? prices.last
    }



    func preload(with tokenId: String, timeframeSecs: Double = CHART_INTERVAL) {
        cleanup()
        preloaded = true
        self.tokenId = tokenId
  

        func fetchPrices() async throws {
            // Fetch both types of data
            let prices = try await fetchInitialPrices(tokenId)
            // Move final status update to main thread
            await MainActor.run {
                self.prices = prices
                self.isReady = true
                if let timestamp = prices.last?.timestamp {
                    self.updatePrice(timestamp: timestamp, priceUsd: prices.last?.priceUsd)
                }
                self.calculatePriceChange()
            }
            subscribeToTokenPrices(tokenId)
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

    func initialize(with tokenId: String, timeframeSecs: Double = CHART_INTERVAL) {
        if initialized { return }
        initialized = true
        if !self.preloaded {
            self.preload(with: tokenId, timeframeSecs: timeframeSecs)
        }

        func fetchCandles() async throws {
           await self.subscribeToCandles(tokenId)
        }

        Task {
            do {
                await startPollingTokenBalance()
                try await retry(fetchCandles)
                await subscribeToSingleTokenData(tokenId)
            }
            catch {
                print("Error fetching candles: \(error)")
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                Token Prices                                */
    /* -------------------------------------------------------------------------- */

    func fetchInitialPrices(_ tokenId: String) async throws -> [Price] {
        let now = Date()
        let startTime = now.addingTimeInterval(-Timespan.live.seconds)
        
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.graphQL.fetch(query: GetTokenPricesSinceQuery(
                token: tokenId,
                since: .some(iso8601Formatter.string(from: startTime))
            )) { result in
                switch result {
                case .success(let graphQLResult):
                    if let _ = graphQLResult.errors {
                        continuation.resume(throwing: TubError.unknown)
                        return
                    }

                    var lastTimestamp: Date?
                    let rawPrices = graphQLResult.data?.api_trade_history ?? []
                    let prices = rawPrices
                        .sorted(by: { $0.created_at < $1.created_at })
                        .reduce(into: [Price]()) { (accumulator, trade) in
                            let timestamp = iso8601Formatter.date(from: trade.created_at) ?? now
                            if let lastTimestamp, abs(timestamp.timeIntervalSince(lastTimestamp)) < 1 {
                                return
                            }
                            lastTimestamp = timestamp
                            accumulator.append(Price(
                                timestamp: timestamp,
                                priceUsd: trade.token_price_usd
                            ))
                        }
                    continuation.resume(returning: prices)
                    return
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func updatePriceIfStale() {
        guard let lastPrice = prices.last else { return }
        let now = Date()
        if now.timeIntervalSince(lastPrice.timestamp) >= PRICE_UPDATE_INTERVAL {
            // Update the price with the last known price
            Task { @MainActor in
                self.updatePrice(timestamp: now, priceUsd: lastPrice.priceUsd)
            }
        }
    }
    
    private func subscribeToTokenPrices(_ tokenId: String) {
        unsubscribeFromTokenPrices()

        // subscribe to price updates
        DispatchQueue.main.async { [weak self] in
            guard let self else {return}
            self.priceSubscription = Network.shared.graphQL.subscribe(
                subscription: SubTokenPricesSinceSubscription(
                    token: tokenId,
                    since: .some(iso8601Formatter.string(from: .now))
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
                            self.updatePrice(timestamp: .now, priceUsd: lastTrade.token_price_usd)
                        }
                    }
                case .failure(let error):
                    print("Error in price subscription: \(error.localizedDescription)")
                }
            }
             // add timer to update price if stale
            priceTimer = Timer.scheduledTimer(withTimeInterval: PRICE_UPDATE_INTERVAL, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.updatePriceIfStale()
            }
        }

       
    }

    private func unsubscribeFromTokenPrices() {
        priceTimer?.invalidate()
        priceTimer = nil
        priceSubscription?.cancel()
        priceSubscription = nil
    }

    /* -------------------------------------------------------------------------- */
    /*                                Token Candles                               */
    /* -------------------------------------------------------------------------- */

    private func fetchInitialCandles(_ tokenId: String, since: Date, candleInterval: String) async throws -> [CandleData] {
        let candles = try await withCheckedThrowingContinuation { continuation in
            Network.shared.graphQL.fetch(query: GetTokenCandlesQuery(token: tokenId, since: .some(iso8601Formatter.string(from: since)), candle_interval: .some(candleInterval))) { result in
                switch result {
                case .success(let graphQLResult):
                    if let candles = graphQLResult.data?.token_trade_history_candles {
                        let now = Date()
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
                        continuation.resume(returning: updatedCandles)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        return candles
    }

    private func subscribeToCandles(_ tokenId: String) async {
        candleSubscription?.cancel()
        candleSubscription = nil

        let now = Date()
        let since: Date = now.addingTimeInterval(-Timespan.candles.seconds)
        let candleInterval = "1m"

        do {
            let candles = try await fetchInitialCandles(tokenId, since: since, candleInterval: candleInterval)
            Task { @MainActor in
                self.candles = candles
            }
        } catch {
            print("Error fetching initial candles: \(error), starting subscription")
        }

        candleSubscription = Network.shared.graphQL.subscribe(
            subscription: SubTokenCandlesSubscription(
                token: tokenId,
                since: .some(iso8601Formatter.string(from: since)),
                candle_interval: .some(candleInterval)
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

    private func subscribeToSingleTokenData(_ tokenId: String) async {
        singleTokenDataSubscription?.cancel()
        
        singleTokenDataSubscription = Network.shared.graphQL.subscribe(
            subscription: SubSingleTokenDataSubscription(token: tokenId)
        ) { result in
            
            switch result {
            case .success(let graphQLResult):
                if let tokenData = graphQLResult.data?.token_stats_interval_comp.first {
                    let liveData = TokenLiveData(
                        supply: Int(tokenData.token_metadata_supply ?? 0),
                        priceUsd: tokenData.latest_price_usd,
                        stats: IntervalStats(volumeUsd: tokenData.total_volume_usd, trades: Int(tokenData.total_trades), priceChangePct: tokenData.price_change_pct),
                        recentStats: IntervalStats(volumeUsd: tokenData.recent_volume_usd, trades: Int(tokenData.recent_trades), priceChangePct: tokenData.recent_price_change_pct)
                    )
                    Task {
                        await UserModel.shared.updateTokenData(mint: tokenId, liveData: liveData)
                    }
                }
            case .failure(let error):
                print("Error in single token data subscription: \(error.localizedDescription)")
            }
        }
    }

    public func updateTokenDetails(_ tokenId: String) {
        DispatchQueue.main.async {
            self.tokenId = tokenId
        }
    }

    private var tokenBalanceTimer: Timer?
    let BALANCE_POLL_INTERVAL: TimeInterval = 30
    
    private func startPollingTokenBalance() async {
        do {
            try await self.refreshTokenBalance()
        } catch {
            print("error fetching token balance: \(error)")
        }
        
        await MainActor.run {
             self.stopPollingTokenBalance()  // Ensure any existing timer is invalidated
             self.tokenBalanceTimer = Timer.scheduledTimer(
                 withTimeInterval: self.BALANCE_POLL_INTERVAL, repeats: true
             ) { [weak self] _ in
                 guard let self = self else { return }
                 Task {
                     do {
                         try await self.refreshTokenBalance()
                     } catch {
                         print("error fetching token balance: \(error)")
                     }
                 }
             }
         }
    }
    
    private func stopPollingTokenBalance() {
        tokenBalanceTimer?.invalidate()
        tokenBalanceTimer = nil
    }
    
    private func refreshTokenBalance() async throws {
        let tokenBalance = try await Network.shared.getTokenBalance(tokenMint: tokenId)

        if tokenBalance > 0 && self.purchaseData == nil {
            try await self.fetchPurchaseData()
        } else if tokenBalance == 0 {
            await MainActor.run {
                self.purchaseData = nil
            }
        }
            
        await UserModel.shared.updateTokenData(mint: tokenId, balance: tokenBalance)
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
        stopPollingTokenBalance()
        unsubscribeFromTokenPrices()

        
        // Clean up subscriptions when the object is deallocated
        candleSubscription?.cancel()
        singleTokenDataSubscription?.cancel()

        isReady = false
        prices = []
        candles = []
        priceChange = (0, 0)
    }

    deinit {
        cleanup()
    }
}
