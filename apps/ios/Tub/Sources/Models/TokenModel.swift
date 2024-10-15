import Apollo
import Combine
import SwiftUI
import TubAPI

class TokenModel: ObservableObject {
    var tokenId: String = ""
    var userId: String = ""

    @Published var token: Token = Token(id: "", name: "COIN", symbol: "SYMBOL")
    @Published var loading = true
    @Published var tokenBalance: (credit: Numeric, debit: Numeric, total: Double) = (0, 0, 0)

    @Published var amountBoughtSol: Double = 0
    @Published var prices: [Price] = []

    private var latestPriceSubscription: Apollo.Cancellable?  // Track the latest price subscription
    private var tokenBalanceSubscription:
        (credit: Apollo.Cancellable?, debit: Apollo.Cancellable?)  // Track the token balance subscription

    init(userId: String, tokenId: String? = nil) {
        self.userId = userId
        if tokenId != nil {
            self.initialize(with: tokenId!)
        }
    }

    private func fetchInitialData() async {
        do {
            try await fetchTokenDetails()
//            self.loading = false
        } catch {
            print("Error fetching initial data: \(error)")
        }
    }

    
    private func fetchTokenDetails() async throws {
        let query = GetTokenDataQuery(tokenId: tokenId)
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
                    if let token = response.data?.token.first(where: { $0.id == self.tokenId }) {
                        DispatchQueue.main.async {
                            self.token = Token(id: token.id, name: token.name, symbol: token.symbol)
//                            self.loading = false
                        }
                        continuation.resume()
                    } else {
                        continuation.resume(
                            throwing:
                                NSError(
                                    domain: "TokenModel",
                                    code: 1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Token not found"
                                    ]
                                )
                        )
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func subscribeToLatestPrice(_ since: Timestamptz) {
        // Cancel any existing subscription before creating a new one
        latestPriceSubscription?.cancel()

        // First, query the past token history
        let query = GetTokenPriceHistorySinceQuery(tokenId: self.tokenId, since: since)
        Network.shared.apollo.fetch(query: query) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.prices = response.data?.token_price_history.compactMap { history in
                        if let date = self.formatDate(history.created_at) {
                            return Price(timestamp: date, price: Double(history.price) / 1e9)
                        }
                        return nil
                    } ?? []
                }
                
                // After fetching past history, subscribe to latest price updates
                self.subscribeToLatestPriceUpdates()
                self.loading = false
                
            case .failure(let error):
                print("Error fetching token price history: \(error)")
            }
        }
    }

    private func subscribeToLatestPriceUpdates() {
        let subscription = SubLatestTokenPriceSubscription(tokenId: self.tokenId)
        
        latestPriceSubscription = Network.shared.apollo.subscribe(subscription: subscription) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let graphQLResult):
                if let latestPrice = graphQLResult.data?.token_price_history.first {
                    DispatchQueue.main.async {
                        if let date = self.formatDate(latestPrice.created_at) {
                            let newPrice = Price(timestamp: date, price: Double(latestPrice.price) / 1e9)
                            self.prices.append(newPrice)
                        }
                    }
                }
            case .failure(let error):
                print("Error in latest price subscription: \(error)")
            }
        }
    }

    private func subscribeToTokenBalance() {
        tokenBalanceSubscription.credit?.cancel()
        tokenBalanceSubscription.debit?.cancel()

        tokenBalanceSubscription.credit = Network.shared.apollo.subscribe(
            subscription: SubAccountTokenBalanceCreditSubscription(
                accountId: Uuid(self.userId), tokenId: self.tokenId)
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    self.tokenBalance.credit =
                        graphQLResult.data?.token_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    self.tokenBalance.total = Double(self.tokenBalance.credit - self.tokenBalance.debit)/1e9
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }

        tokenBalanceSubscription.debit = Network.shared.apollo.subscribe(
            subscription: SubAccountTokenBalanceDebitSubscription(
                accountId: Uuid(self.userId), tokenId: self.tokenId)
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    self.tokenBalance.debit =
                        graphQLResult.data?.token_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    self.tokenBalance.total = Double(self.tokenBalance.credit - self.tokenBalance.debit)/1e9
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    private lazy var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private func formatDate(_ dateString: String) -> Date? {
        return iso8601Formatter.date(from: dateString)
    }

    func buyTokens(buyAmountSol: Double, completion: ((Bool) -> Void)?) {
        let buyAmountLamps = String(Int(buyAmountSol * 1e9))

        Network.shared.buyToken(
            accountId: self.userId, tokenId: self.tokenId, amount: buyAmountLamps
        ) { result in
            switch result {
            case .success:
                print("buy successful")
                self.amountBoughtSol = buyAmountSol
                completion?(true)
            case .failure(let error):
                print(error)
                completion?(false)
            }
        }
    }

    func sellTokens(completion: ((Bool) -> Void)?) {
        let sellAmountLamps = String(Int(self.amountBoughtSol * 1e9))

        Network.shared.sellToken(
            accountId: self.userId, tokenId: self.tokenId, amount: sellAmountLamps
        ) { result in
            switch result {
            case .success:
                completion?(true)
            case .failure(_):
                completion?(false)
            }
        }
    }

    func initialize(with newTokenId: String) {
        // Cancel all existing subscriptions
        latestPriceSubscription?.cancel()
        tokenBalanceSubscription.credit?.cancel()
        tokenBalanceSubscription.debit?.cancel()

        // Reset properties if necessary
        self.tokenId = newTokenId
        self.loading = true  // Reset loading state if needed
        self.prices = []

        // Re-run the initialization logic
        Task {
            await fetchInitialData()
            
            let thirtySecondsAgo = Date().addingTimeInterval(-30).ISO8601Format()
            subscribeToLatestPrice(thirtySecondsAgo)
            subscribeToTokenBalance()
        }
    }
    
    func updateHistoryTimespan(timespan: Double) {
        latestPriceSubscription?.cancel()
        self.prices = []
        self.loading = true
        let timespanAgo = Date().addingTimeInterval(-timespan).ISO8601Format()
        subscribeToLatestPrice(timespanAgo)
    }
}
