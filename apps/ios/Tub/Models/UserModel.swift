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
    @Published var userId: String
    @Published var username: String = ""
    
    @AppStorage("userId") private var storedUserId: String?
    @AppStorage("username") private var storedUsername: String?
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(userId: String) {
        self.userId = userId
        Task {
            await fetchInitialData()
            startBalancePolling()
        }
    }
    
    private func fetchInitialData() async {
        do {
            // Validate userId is a valid UUID
            guard UUID(uuidString: userId) != nil else {
                throw NSError(domain: "UserModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid userId: Not a valid UUID"])
            }
            
            try await fetchAccountData()
            DispatchQueue.main.async {
                self.isLoading = false  // Use isLoading instead of loading
            }
        } catch {
            print("Error fetching initial data: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false  // Set isLoading to false even on error
            }
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
                            // Add any other properties you want to set from the account data
                        }
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: NSError(domain: "UserModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Account not found"]))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
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
    
    func logout() {
        // Clear the stored values
        storedUserId = nil
        storedUsername = nil
        
        // Reset the published properties
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.userId = ""
            self.username = ""
            self.balance = 0
            self.isLoading = true
        }
        
        // Cancel any ongoing network requests or timers
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
