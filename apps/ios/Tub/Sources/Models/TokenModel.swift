import Apollo
import Combine
import SwiftUI
import TubAPI

/**
 * This class is responsible for fetching and storing token data, mostly for the current token that is being shown.
 * It will keep its price and candles data up to date.
*/
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
    private var tokenLiveDataPollingTimer: Timer?

    private var preloaded = false
    private var initialized = false
    
    @Published var purchaseData: PurchaseData? 
    private let activityManager = LiveActivityManager.shared

    private var priceTimer: Timer? = nil

    private func fetchPurchaseData() async throws {
        if self.purchaseData != nil {
            return
        }
        
        guard let walletAddress = UserModel.shared.walletAddress else { return }
        
        let query = GetLatestTokenPurchaseQuery(wallet: walletAddress, mint: tokenId)
        let purchaseData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PurchaseData?, Error>) in
            Network.shared.graphQL.fetch(query: query, bypassCache: true) {
                result in switch result {
                case .success(let response):
                    if let err = response.errors?.first?.message {
                        continuation.resume(throwing: TubError.serverError(reason:err))
                        return
                    }
                    guard let tx = response.data?.transactions.first, let timestamp = iso8601Formatter.date(from: tx.created_at) else {
                        continuation.resume(returning: nil)
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
        
        if let purchaseData = self.purchaseData {
            let gains = priceUsd - purchaseData.priceUsd
            let gainsPercentage = (gains / purchaseData.priceUsd) * 100
            Task {
                LiveActivityManager.shared.updatePriceChange(
                    currentPriceUsd: priceUsd,
                    gainsPercentage: gainsPercentage
                )
            }
        }
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
                await startTokenLiveDataPolling(tokenId)
                try await retry(fetchCandles)
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
            Network.shared.graphQL.fetch(
                query: GetTokenPricesSinceQuery(
                    token: tokenId,
                    since: .some(iso8601Formatter.string(from: startTime))
                ),
                bypassCache: true
            ) { result in
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

    private func fetchInitialCandles(_ tokenId: String, since: Date) async throws -> [CandleData] {
        let candles = try await withCheckedThrowingContinuation { continuation in
            Network.shared.graphQL.fetch(
                query: GetTokenCandlesSinceQuery(
                    token: tokenId,
                    since: .some(iso8601Formatter.string(from: since))
                ),
                bypassCache: true
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let candles = graphQLResult.data?.token_candles_history_1min {
                        let now = Date()
                        let updatedCandles = candles.map { candle in
                            CandleData(
                                start: iso8601FormatterNoFractional.date(from: candle.bucket) ?? now,
                                end: (iso8601FormatterNoFractional.date(from: candle.bucket) ?? now).addingTimeInterval(60),
                                open: candle.open_price_usd,
                                close: candle.close_price_usd,
                                high: candle.high_price_usd,
                                low: candle.low_price_usd,
                                volume: candle.volume_usd,
                                hasTrades: candle.has_trades
                            )
                        }
                        continuation.resume(returning: updatedCandles)
                        return
                    } else {
                        continuation.resume(throwing: TubError.actionFailed(failureDescription: "No candles found"))
                        return
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                    return
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

        do {
            let candles = try await fetchInitialCandles(tokenId, since: since)
            Task { @MainActor in
                self.candles = candles
            }
        } catch {
            print("Error fetching initial candles: \(error), starting subscription")
        }

        candleSubscription = Network.shared.graphQL.subscribe(
            subscription: SubTokenCandlesSinceSubscription(
                token: tokenId,
                since: .some(iso8601Formatter.string(from: since))
            )
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let graphQLResult):
                if let candles = graphQLResult.data?.token_candles_history_1min {
                    let updatedCandles = candles.map { candle in
                        CandleData(
                            start: iso8601FormatterNoFractional.date(from: candle.bucket) ?? now,
                            end: (iso8601FormatterNoFractional.date(from: candle.bucket) ?? now).addingTimeInterval(60),
                            open: candle.open_price_usd,
                            close: candle.close_price_usd,
                            high: candle.high_price_usd,
                            low: candle.low_price_usd,
                            volume: candle.volume_usd,
                            hasTrades: candle.has_trades
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

    /* -------------------------------------------------------------------------- */
    /*                                  Live data                                 */
    /* -------------------------------------------------------------------------- */

    private func getTokenLiveData(_ tokenId: String) async throws -> TokenLiveData {
        return try await withCheckedThrowingContinuation { 
            (continuation: CheckedContinuation<TokenLiveData, Error>) in
            Network.shared.graphQL.fetch(
                query: GetTokenLiveDataQuery(token: tokenId),
                cachePolicy: .fetchIgnoringCacheData,
                cacheTime: QUERY_TOKEN_LIVE_DATA_CACHE_TIME
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let tokenData = graphQLResult.data?.token_rolling_stats_30min.first {
                        let liveData = TokenLiveData(
                            supply: Int(tokenData.supply ?? 0),
                            priceUsd: tokenData.latest_price_usd,
                            stats: IntervalStats(
                                volumeUsd: tokenData.volume_usd_30m,
                                trades: Int(tokenData.trades_30m),
                                priceChangePct: tokenData.price_change_pct_30m
                            ),
                            recentStats: IntervalStats(
                                volumeUsd: tokenData.volume_usd_1m,
                                trades: Int(tokenData.trades_1m),
                                priceChangePct: tokenData.price_change_pct_1m
                            )
                        )
                        continuation.resume(returning: liveData)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func updateTokenLiveData() {
        Task {
            do {
                let liveData = try await getTokenLiveData(tokenId)
                await UserModel.shared.updateTokenData(mint: tokenId, liveData: liveData)
            } catch {
                print("Error in single token data fetch: \(error.localizedDescription)")
            }
        }
    }

    private func startTokenLiveDataPolling(_ tokenId: String) async {
        stopTokenLiveDataPolling()
        
        // Initial fetch
        updateTokenLiveData()
        
        // Setup polling timer on main thread
        await MainActor.run {
            tokenLiveDataPollingTimer = Timer.scheduledTimer(
                withTimeInterval: TOKEN_LIVE_DATA_POLLING_INTERVAL,
                repeats: true
            ) { [weak self] _ in
                self?.updateTokenLiveData()
            }
        }
    }

    private func stopTokenLiveDataPolling() {
        tokenLiveDataPollingTimer?.invalidate()
        tokenLiveDataPollingTimer = nil
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
            DispatchQueue.main.async {
                self.priceChange = (0, 0)
            }
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
        stopTokenLiveDataPolling()
        
        // Clean up subscriptions when the object is deallocated
        candleSubscription?.cancel()

        isReady = false
        prices = []
        candles = []
        priceChange = (0, 0)
    }

    deinit {
        cleanup()
    }
}
