import SwiftUI
import Apollo
import TubAPI
import Combine

class RemoteCoinModel: BaseCoinModel {
    
    private var cancellables: Set<AnyCancellable> = []
    
    override init(userId: String, tokenId: String) {
        super.init(userId: userId, tokenId: tokenId)
        
        Task {
            await fetchInitialData()
            subscribeToLatestPrice()
            startCoinBalancePolling()
        }
    }
    
    private lazy var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private func fetchInitialData() async {
        do {
            try await fetchTokenDetails()
            self.loading = false
        } catch {
            print("Error fetching initial data: \(error)")
        }
    }
    
    private func fetchTokenDetails() async throws {
        let query = GetAllTokensQuery()
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "RemoteCoinModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
                switch result {
                case .success(let response):
                    if let token = response.data?.token.first(where: { $0.id == self.tokenId }) {
                        DispatchQueue.main.async {
                            self.coin = Coin(id: token.id, name: token.name, symbol: token.symbol)
                            self.loading = false
                        }
                        continuation.resume()
                    } else {
                        continuation.resume(
                            throwing:
                                NSError(
                                    domain: "RemoteCoinModel",
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
    
    private func subscribeToLatestPrice() {
        let _ = Network.shared.apollo.subscribe(subscription: GetLatestTokenPriceSubscription(tokenId: self.tokenId)) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    if let history = graphQLResult.data?.token_price_history.first {

                        if let date = formatDate(history.created_at) {
                            let newPrice = Price(timestamp: date, price: Double(history.price) / 1e9)
                            self.prices.append(newPrice)
                        } else {
                            print("Failed to parse date: \(history.created_at)")
                        }
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func startCoinBalancePolling() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchCoinBalance()
            }
            .store(in: &cancellables)
    }
    
    private func fetchCoinBalance() {
        let creditQuery = GetAccountTokenCreditQuery(accountId: Uuid(userId), tokenId: self.tokenId)
        let debitQuery = GetAccountTokenDebitQuery(accountId: Uuid(userId), tokenId: self.tokenId)
        
        let creditPublisher = Network.shared.apollo.watchPublisher(query: creditQuery)
        let debitPublisher = Network.shared.apollo.watchPublisher(query: debitQuery)
        
        Publishers.CombineLatest(creditPublisher, debitPublisher)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Error fetching balance: \(error)")
                }
            } receiveValue: { [weak self] creditResult, debitResult in
                switch (creditResult, debitResult) {
                case (.success(let creditData), .success(let debitData)):
                    let creditAmount = creditData.data?.token_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    let debitAmount = debitData.data?.token_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    let balance = Double(creditAmount - debitAmount) / 1e9
                    DispatchQueue.main.async {
                        self?.coinBalance = balance
                    }
                case (.failure(let error), _), (_, .failure(let error)):
                    print("Error fetching balance: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    override func buyTokens(buyAmount: Double, completion: ((Bool) -> Void)?) {
        print("in handleBuy")
        let buyAmountLamps = String(Int(buyAmount * 1e9))
        
        Network.shared.buyToken(accountId: self.userId, tokenId: self.tokenId, amount: buyAmountLamps) { result in
            switch result {
            case .success:
                print("success")
                completion?(true)
            case .failure(let error):
                print("failure", error.localizedDescription)
                completion?(false)
            }
        }
    }
    
    override func sellTokens(completion: ((Bool) -> Void)?) {
        let sellAmountLamps = String(Int(self.amountBought * 1e9))
        
        Network.shared.sellToken(accountId: self.userId, tokenId: self.tokenId, amount: sellAmountLamps) { result in
            switch result {
            case .success:
                print("success")
                completion?(true)
            case .failure(let error):
                print("failure", error)
                completion?(false)
            }
        }
    }
}

