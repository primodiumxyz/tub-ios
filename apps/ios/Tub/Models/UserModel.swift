//
//  PlayerModel.swift
//  Tub
//
//  Created by Henry on 10/3/24.
//

import SwiftUI
import Combine
import TubAPI
import ApolloCombine

class UserModel: ObservableObject {
    @Published var balance: Double = 0
    @Published var isLoading: Bool = true
    private var cancellables: Set<AnyCancellable> = []
    
    let userId: String
    var username: String = ""
    var loading: Bool = true
    
    
    
    init(userId: String) {
        self.userId = userId
        Task {
            await fetchInitialData()
            startBalancePolling()
        }
    }
    
    private func fetchInitialData() async {
        do {
            try await fetchBalance()
            self.isLoading = false
        } catch {
            print("Error fetching initial data: \(error)")
        }
    }

    private func fetchAccountData() async throws {
        let query = GetAccountDataQuery(accountId: Uuid(userId))
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "UserModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
                switch result {
                case .success(let response):
                    if let account = response.data?.account.first {
                        DispatchQueue.main.async {
                            self.username = account.username
                            self.loading = false
                            // Add any other properties you want to set from the account data
                        }
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: NSError(domain: "UserModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Account not found"]))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                    self.loading = false
                }
            }
        }
    }
    
    private func startBalancePolling() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchBalance()
            }
            .store(in: &cancellables)
    }
    
    private func fetchBalance() {
        let creditQuery = GetAccountBalanceCreditQuery(accountId: Uuid(userId))
        let debitQuery = GetAccountBalanceDebitQuery(accountId: Uuid(userId))
        
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
                    let creditAmount = creditData.data?.account_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    let debitAmount = debitData.data?.account_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    let balance = Double(creditAmount - debitAmount) / 1e9
                    DispatchQueue.main.async {
                        self?.balance = balance
                    }
                case (.failure(let error), _), (_, .failure(let error)):
                    print("Error fetching balance: \(error)")
                }
            }
            .store(in: &cancellables)
    }
}
