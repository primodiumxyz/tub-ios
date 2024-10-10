import SwiftUI
import Apollo
import TubAPI
import Combine

class TokenModel: BaseTokenModel {
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(userId: String) {
        super.init()
        self.userId = userId
    }

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
                    continuation.resume(throwing: NSError(domain: "TokenModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
                switch result {
                case .success(let response):
                    if let token = response.data?.token.first(where: { $0.id == self.tokenId }) {
                        DispatchQueue.main.async {
                            self.token = Token(id: token.id, name: token.name, symbol: token.symbol)
                            self.loading = false
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
    
    private func startTokenBalancePolling() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchTokenBalance()
            }
            .store(in: &cancellables)
    }
    
    private func fetchTokenBalance() {
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
                        self?.tokenBalance = balance
                    }
                case (.failure(let error), _), (_, .failure(let error)):
                    print("Error fetching balance: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    override func buyTokens(buyAmount: Double, completion: ((Bool) -> Void)?) {
        let buyAmountLamps = String(Int(buyAmount * 1e9))
        
        Network.shared.buyToken(accountId: self.userId, tokenId: self.tokenId, amount: buyAmountLamps) { result in
            switch result {
            case .success:
                completion?(true)
            case .failure(let error):
                completion?(false)
            }
        }
    }
    
    override func sellTokens(completion: ((Bool) -> Void)?) {
        let sellAmountLamps = String(Int(self.amountBoughtSol * 1e9))
        
        Network.shared.sellToken(accountId: self.userId, tokenId: self.tokenId, amount: sellAmountLamps) { result in
            switch result {
            case .success:
                completion?(true)
            case .failure(let error):
                completion?(false)
            }
        }
    }
    
    func initialize(with newTokenId: String) {
        // Cancel all existing cancellables
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Reset properties if necessary
        self.tokenId = newTokenId
        self.loading = true // Reset loading state if needed
        self.prices = []
        
        // Re-run the initialization logic
        Task {
            await fetchInitialData()
            subscribeToLatestPrice()
            startTokenBalancePolling()
        }
    }
}

