import Apollo
import Combine
import SwiftUI
import TubAPI

class TokenModel: ObservableObject {
    var tokenId: String = ""

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

    @Published var prices: [Price] = []
    @Published var priceChange: (amountLamps: Int, percentage: Double) = (0, 0)

    @Published var timeframeSecs: Double = CHART_INTERVAL
    @Published var currentTimeframe: Timespan = .live
    private var lastPriceTimestamp: Date?

    private var latestPriceSubscription: Apollo.Cancellable?

    deinit {
        // Clean up subscriptions when the object is deallocated
        latestPriceSubscription?.cancel()
    }

    init(tokenId: String? = nil) {
        if tokenId != nil {
            self.initialize(with: tokenId!)
        }
    }
    
    func initialize(with newTokenId: String, timeframeSecs: Double = CHART_INTERVAL) {
        // Cancel all existing subscriptions
        latestPriceSubscription?.cancel()

        // Reset properties if necessary
        self.tokenId = newTokenId
        self.loading = true  // Reset loading state if needed
        self.prices = []
        self.priceChange = (0, 0)
        self.timeframeSecs = timeframeSecs

        // Re-run the initialization logic
        Task {
            do {
                try await fetchTokenDetails()
                try await fetchInitialPrices(self.timeframeSecs)
                self.loading = false
            } catch {
                print("Error fetching initial data: \(error)")
            }

            subscribeToLatestPrice()
        }
    }

    func fetchInitialPrices(_ timeframeSecs: Double) async throws {
        let since = Date().addingTimeInterval(-timeframeSecs).ISO8601Format()

        let query = GetTokenPriceHistorySinceQuery(tokenId: Uuid(tokenId), since: since)

        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query) { [weak self] result in
                guard let self = self else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "TokenModel", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }

                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.prices =
                            response.data?.token_price_history.compactMap { history in
                                if let date = formatDateString(history.created_at) {
                                    return Price(timestamp: date, price: history.price)
                                }
                                return nil
                            } ?? []
                        self.lastPriceTimestamp = self.prices.last?.timestamp
                        self.loading = false
                        self.calculatePriceChange()
                    }
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchTokenDetails() async throws {
        let query = GetTokenDataQuery(tokenId: tokenId)
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) {
                [weak self] result in
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
        let subscription = SubLatestTokenPriceSubscription(tokenId: Uuid(self.tokenId))

        latestPriceSubscription = Network.shared.apollo.subscribe(subscription: subscription) {
            [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let graphQLResult):
                if let priceHistory = graphQLResult.data?.token_price_history.first,
                    let date = formatDateString(priceHistory.created_at)
                {
                    let newPrice = Price(timestamp: date, price: priceHistory.price)
                    if self.lastPriceTimestamp == nil
                        || newPrice.timestamp > self.lastPriceTimestamp!
                    {
                        self.prices.append(newPrice)
                        self.lastPriceTimestamp = newPrice.timestamp
                        self.calculatePriceChange()
                    }

                }
            case .failure(let error):
                print("Error in latest price subscription: \(error)")
            }
        }
    }

    func updateHistoryInterval(_ timespan: Timespan) {
        self.currentTimeframe = timespan
        self.calculatePriceChange()

        if self.timeframeSecs >= timespan.timeframeSecs {
            return
        }

        latestPriceSubscription?.cancel()
        self.prices = []
        self.loading = true
        self.timeframeSecs = timespan.timeframeSecs
        Task {
            do {
                try await fetchInitialPrices(timeframeSecs)
                subscribeToLatestPrice()
            } catch {
                print("error updating the history interval: \(error.localizedDescription)")
            }

        }
    }

    private func calculatePriceChange() {
        let latestPrice = prices.last?.price ?? 0

        // Get timestamp for start of current timeframe
        let startTime = Date().addingTimeInterval(-currentTimeframe.timeframeSecs)

        // Find first price after the start time
        let initialPrice =
            prices.first(where: { $0.timestamp >= startTime })?.price ?? prices.first?.price ?? 0

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
        let marketCap =
            Double(token.supply) / pow(10.0, Double(token.decimals)) * Double(currentPrice)  // we're dividing first otherwise it will overflow...
        let supplyValue = Double(token.supply) / pow(10.0, Double(token.decimals))

        return [
            ("Market Cap", loading ? "..." : priceModel.formatPrice(lamports: Int(marketCap))),
            (
                "Volume (\(formatDuration(token.volume.interval)))",
                loading
                    ? "..."
                    : priceModel.formatPrice(lamports: token.volume.value, formatLarge: true)
            ),
            ("Supply", loading ? "..." : formatLargeNumber(supplyValue)),
        ]
    }
}
