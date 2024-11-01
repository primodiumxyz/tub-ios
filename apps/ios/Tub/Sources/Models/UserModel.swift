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
    
    @Published var userId: String
    @Published var username: String = ""
    @Published var walletAddress: String  = ""

    @Published var initialBalanceLamps: Int = 0
    @Published var balanceLamps: Int = 0
    @Published var balanceChangeLamps: Int = 0
    
    
    @Published var initialTime: Date = Date()
    @Published var currentTime: Date = Date()
    @Published var timeElapsed: TimeInterval = 0

    private var cancellables: Set<AnyCancellable> = []
    private var accountBalanceSubscription: Apollo.Cancellable?
    private var timerCancellable: AnyCancellable?
    
    @Published var isLoading: Bool = true

    init(userId: String, mock: Bool? = false) {
        self.userId = userId
        print("wallet state:", privy.embeddedWallet.embeddedWalletState.toString)
        
        self.updateWalletAddress()
        
        privy.embeddedWallet.setEmbeddedWalletStateChangeCallback { [weak self] state in
            print("updating wallet in UserModel")
            self?.updateWalletAddress()
        }
        
        if(mock == true) {
            self.balanceLamps = 1000
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
            try await fetchAccountData()
            try await fetchInitialBalance()
            DispatchQueue.main.async {
                self.initialTime = Date()
                self.isLoading = false
            }
        } catch {
            print("Error fetching initial data: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    private func fetchAccountData() async throws {
        let query = GetAccountDataQuery(accountId: userId)
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
    
    private func fetchInitialBalance() async throws {
        let query = GetAccountBalanceQuery(account: userId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Network.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "UserModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.initialBalanceLamps = response.data?.balance.first?.value ?? 0
                    }
                    continuation.resume()
                case .failure(let error):
                    print("Error fetching initial balance: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func subscribeToAccountBalance() {
        accountBalanceSubscription?.cancel()
        
        accountBalanceSubscription = Network.shared.apollo.subscribe(
            subscription: SubAccountBalanceSubscription(
                account: self.userId)
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    self.balanceLamps =
                    graphQLResult.data?.balance.first?.value ?? 0
                    self.balanceChangeLamps = self.balanceLamps - self.initialBalanceLamps
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
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

    private func updateWalletAddress() {
        switch privy.embeddedWallet.embeddedWalletState {
        case .connected(let wallets):
            if let wallet = wallets.first {
                DispatchQueue.main.async {
                    self.walletAddress = wallet.address
                }
            } else {
                DispatchQueue.main.async {
                    self.walletAddress = ""
                }
                print("No wallet found in connected state")
            }
        default:
            DispatchQueue.main.async {
                self.walletAddress = ""
            }
            print("Wallet must be connected to initialize UserModel")
        }
    }

    func logout() {
        privy.logout()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.userId = ""
            self.username = ""
            self.balanceLamps = 0
            self.balanceChangeLamps = 0
            self.isLoading = true
        }
        
        // Cancel any ongoing network requests or timers
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        timerCancellable?.cancel()
        
    }
}
