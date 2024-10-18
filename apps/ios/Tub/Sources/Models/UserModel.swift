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
    private lazy var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    @Published var balance: (credit: Numeric, debit: Numeric, total: Double) = (0, 0, 0)
    @Published var isLoading: Bool = true
    @Published var userId: String
    @Published var username: String = ""
    @Published var balanceChange: Double = 0
    @Published var timeElapsed: TimeInterval = 0
    @Published var initialBalance: Double = 0
    @Published var initialTime: Date = Date()
    @Published var currentTime: Date = Date()
    
    @AppStorage("userId") private var storedUserId: String?
    @AppStorage("username") private var storedUsername: String?
    
    private var cancellables: Set<AnyCancellable> = []
    private var accountBalanceSubscription:
        (credit: Apollo.Cancellable?, debit: Apollo.Cancellable?)  // Track the token balance subscription
    private var timerCancellable: AnyCancellable?

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
            startTimeElapsedTimer()
        }
    }

    private func fetchInitialData() async {
        do {
            // Validate userId is a valid UUID
            guard UUID(uuidString: userId) != nil else {
                throw NSError(domain: "UserModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid userId: Not a valid UUID"])
            }
            
            try await fetchAccountData()
            try await fetchInitialBalance()
            DispatchQueue.main.async {
                self.initialTime = Date()
                self.isLoading = false
            }
        } catch {
            print("Error fetching initial data: \(error)")
            storedUserId = ""
            storedUsername = ""
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    private func fetchInitialBalance() async throws {
        let query = GetAccountBalanceQuery(accountId: Uuid(userId), at: .init(stringLiteral: iso8601Formatter.string(from: Date())))
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Network.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "UserModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
                switch result {
                case .success(let response):
                    let credit = response.data?.credit.aggregate?.sum?.amount ?? 0
                    let debit = response.data?.debit.aggregate?.sum?.amount ?? 0
                    let balance = Double(credit - debit) / 1e9
                    DispatchQueue.main.async {
                        self.initialBalance = balance
                    }
                    continuation.resume()
                case .failure(let error):
                    print("Error fetching initial balance: \(error)")
                    continuation.resume(throwing: error)
                }
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
                    self.updateBalanceAndChange()
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
                    self.updateBalanceAndChange()
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateBalanceAndChange() {
        self.balance.total = Double(self.balance.credit - self.balance.debit) / 1e9
        self.balanceChange = self.balance.total - self.initialBalance
    }

    private func startTimeElapsedTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.currentTime = Date()
                self.timeElapsed = self.currentTime.timeIntervalSince(self.initialTime)
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
        timerCancellable?.cancel()
    }
}
