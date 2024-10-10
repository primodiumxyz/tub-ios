import SwiftUI
import Apollo
import TubAPI
import Combine

class TokenModel: ObservableObject {
    var tokenId: String = ""
    var userId: String = ""
    
    @Published var token: Token = Token(id: "", name: "COIN", symbol: "SYMBOL")
    @Published var loading = true
    @Published var tokenBalance: Double = 0
    
    @Published var amountBoughtSol: Double = 0
    @Published var prices: [Price] = []  
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(userId: String, tokenId: String? = nil) {
        self.userId = userId
        if(tokenId != nil){
            self.initialize(with: tokenId!)
        }
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

                        if let date = self.formatDate(history.created_at) {
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
        
        Network.shared.buyToken(accountId: self.userId, tokenId: self.tokenId, amount: buyAmountLamps) { result in
            switch result {
            case .success:
                print("buy successful")
                completion?(true)
            case .failure(let error):
                print(error)
                completion?(false)
            }
        }
    }
    
    func sellTokens(completion: ((Bool) -> Void)?) {
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
        print("initializing \(newTokenId)")
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

