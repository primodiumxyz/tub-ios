//
//  PlayerModel.swift
//  Tub
//
//  Created by Henry on 10/3/24.
//

import SwiftUI
import Combine
import Apollo
import TubAPI
import ApolloCombine

class UserModel: ObservableObject {
    @Published var balance: (credit: Numeric, debit: Numeric, total: Double) = (0, 0, 0)
    @Published var isLoading: Bool = true
    @Published var userId: String
    @Published var username: String = ""
    
    @AppStorage("userId") private var storedUserId: String?
    @AppStorage("username") private var storedUsername: String?
    
    private var cancellables: Set<AnyCancellable> = []
    private var accountBalanceSubscription:
        (credit: Apollo.Cancellable?, debit: Apollo.Cancellable?)  // Track the token balance subscription

    
    init(userId: String, mock: Bool? = false) {
        self.userId = userId
        
        if(mock == true) {
            self.balance.total = 1000
            isLoading = false
            return
        }
        
        Task {
            await fetchInitialData()
            subscribeToAccountBalance()
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
            storedUserId = ""
            storedUsername = ""
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
    
    private func subscribeToAccountBalance() {
        accountBalanceSubscription.credit?.cancel()
        accountBalanceSubscription.debit?.cancel()
        
        accountBalanceSubscription.credit = Network.shared.apollo.subscribe(
            subscription: SubAccountBalanceCreditSubscription(
                accountId: Uuid(self.userId))
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    self.balance.credit =
                    graphQLResult.data?.account_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    self.balance.total = Double(self.balance.credit - self.balance.debit)/1e9
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }

        accountBalanceSubscription.debit = Network.shared.apollo.subscribe(
            subscription: SubAccountBalanceDebitSubscription(
                accountId: Uuid(self.userId))
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    self.balance.debit =
                    graphQLResult.data?.account_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    self.balance.total = Double(self.balance.credit - self.balance.debit)/1e9
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
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
            self.balance = (0, 0, 0)
            self.isLoading = true
        }
        
        // Cancel any ongoing network requests or timers
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
    }
}
