//
//  GlobalUserModel.swift
//  Tub
//
//  Created by Henry on 11/14/24.
//

import SwiftUI
import Combine
import Apollo
import TubAPI
import ApolloCombine
import PrivySDK

final class UserModel: ObservableObject {
    static let shared = UserModel()
    
    @EnvironmentObject private var notificationHandler: NotificationHandler
    
    @Published var isLoading: Bool = false
    @Published var userId: String?
    @Published var walletState: EmbeddedWalletState = .notCreated
    @Published var walletAddress: String?
    @Published var error: Error?
    
    @Published var balanceLamps: Int? = nil
    @Published var initialTime = Date()
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var initialBalanceLamps: Int? = nil
    @Published var balanceChangeLamps: Int = 0
    
    private var accountBalanceSubscription: Apollo.Cancellable?
    
    private var timer: Timer?
    
    private init() {
        Task {
            try await CodexTokenManager.shared.handleUserSession()
        }
        setupAuthStateListener()
        setupWalletStateListener()
    }



    private func setupAuthStateListener() {
        privy.setAuthStateChangeCallback { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .authenticated(let authSession):
                self.userId = authSession.user.id
                self.startTimer()
            case .unauthenticated:
                DispatchQueue.main.async {
                    self.userId = nil
                    self.walletState = .notCreated
                    self.walletAddress = nil
                    self.stopTimer()
                    self.elapsedSeconds = 0
                }
            default:
                break
            }
        }
    }
    
    private func setupWalletStateListener() {
        privy.embeddedWallet.setEmbeddedWalletStateChangeCallback { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .error:
                notificationHandler.show("Failed to connect wallet.", type: .error)
            case .connected(let wallets):
                if let solanaWallet = wallets.first(where: { $0.chainType == .solana }), walletAddress == nil {
                    self.walletAddress = solanaWallet.address
                    Task {
                        await self.initializeUser()
                    }
                }
            default:
                break
            }
            self.walletState = state
        }
    }
    
    func initializeUser() async {
        self.error = nil
        let timeoutTask = Task {
            self.isLoading = true
            try await Task.sleep(nanoseconds: 10 * 1_000_000_000) // 10 seconds
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isLoading {
                    self.isLoading = false
                }
            }
        }
        
        do {
            try await fetchInitialBalance()
            subscribeToAccountBalance()
            timeoutTask.cancel() // Cancel timeout if successful
            DispatchQueue.main.async {
                self.initialTime = Date()
                self.isLoading = false
            }
        } catch {
            timeoutTask.cancel() // Cancel timeout if there's an error
            DispatchQueue.main.async {
                self.isLoading = false
            }
            self.error = error
        }
    }
    
    private func fetchInitialBalance() async throws {
        guard let walletAddress = self.walletAddress else {
            return
        }
        let query = GetWalletBalanceQuery(wallet: walletAddress)
        
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
        guard let walletAddress = self.walletAddress else { return }
        if let sub = accountBalanceSubscription { sub.cancel() }
        
        accountBalanceSubscription = Network.shared.apollo.subscribe(
            subscription: SubWalletBalanceSubscription(
                wallet: walletAddress)
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    let balance = graphQLResult.data?.balance.first?.value ?? 0
                    
                    self.balanceLamps = balance
                    if let initialBalanceLamps = self.initialBalanceLamps {
                        self.balanceChangeLamps = balance - initialBalanceLamps
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getLinkedAccounts() -> (email: String?, phone: String?, embeddedWallets: [PrivySDK.EmbeddedWallet]) {
        
        switch privy.authState {
        case .authenticated(let session):
            let linkedAccounts = session.user.linkedAccounts
            
            var email: String? {
                linkedAccounts.first { account in
                    if case .email(_) = account {
                        return true
                    }
                    return false
                }.flatMap { account in
                    if case .email(let emailAccount) = account {
                        return emailAccount.email
                    }
                    return nil
                }
            }
            
            var phone: String? {
                linkedAccounts.first { account in
                    if case .phone = account {
                        return true
                    }
                    return false
                }.flatMap { account in
                    if case .phone(let phoneAccount) = account {
                        return phoneAccount.phoneNumber
                    }
                    return nil
                }
            }
            
            var embeddedWallets: [PrivySDK.EmbeddedWallet] {
                linkedAccounts.compactMap { account in
                    if case .embeddedWallet(let wallet) = account {
                        return wallet
                    }
                    return nil
                }
            }
            return (email, phone, embeddedWallets)
        default:
            return (nil, nil, [])
        }
    }
    
    func logout() {
        if userId == nil { return }
        self.walletState = .notCreated
        self.walletAddress = nil
        self.balanceLamps = 0
        self.initialBalanceLamps = nil
        self.balanceChangeLamps = 0
        self.stopTimer()
        self.elapsedSeconds = 0
        deinitToken()
        privy.logout()
    }


    /* ------------------------------- USER TOKEN ------------------------------- */

    @Published var tokenId: String? = nil
    @Published var tokenBalanceLamps: Int? = nil

    @Published var purchaseData: PurchaseData? = nil
    
    private var tokenBalanceSubscription: Apollo.Cancellable?

    func initToken(tokenId: String) {
        guard let walletAddress else { return }
        deinitToken()

        self.tokenId = tokenId
        subscribeToTokenBalance(walletAddress: walletAddress, tokenId: tokenId)
    }

    func deinitToken() {
        tokenBalanceSubscription?.cancel()
        self.tokenBalanceLamps = nil
        self.tokenId = nil
    }

    private func subscribeToTokenBalance(walletAddress: String, tokenId: String) {
        tokenBalanceSubscription?.cancel()

        tokenBalanceSubscription = Network.shared.apollo.subscribe(
            subscription: SubWalletTokenBalanceSubscription(
                wallet: walletAddress, token: tokenId)
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    self.balanceLamps =
                        graphQLResult.data?.balance.first?.value ?? 0
                case .failure(let error):
                    print("Error updating token balance: \(error.localizedDescription)")
                }
            }
        }
    }

    func buyTokens(
        buyAmountLamps: Int, price: Int, completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        guard let tokenId = self.tokenId  else {
            return
        }
            let tokenAmount = Int(Double(buyAmountLamps) / Double(price) * 1e9)
            var errorMessage: String? = nil

            Network.shared.buyToken(
                tokenId: tokenId, amount: String(tokenAmount), tokenPrice: String(price)
            ) { result in
                switch result {
                case .success:
                    self.purchaseData = PurchaseData(
                        timestamp: Date(),
                        amount: buyAmountLamps,
                        price: price
                    )
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("Error buying tokens: \(error)")
                }
                completion(result)
            }

            Network.shared.recordClientEvent(
                event: ClientEvent(
                    eventName: "buy_tokens",
                    source: "token_model",
                    metadata: [
                        ["token_amount": tokenAmount],
                        ["buy_amount": buyAmountLamps],
                        ["price": price],
                        ["token_id": tokenId],
                    ],
                    errorDetails: errorMessage
                )
            ) { result in
                switch result {
                case .success:
                    print("Successfully recorded buy event")
                case .failure(let error):
                    print("Failed to record buy event: \(error)")
                }
            }
    }

    func sellTokens(price: Int, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        guard let tokenId = self.tokenId, let balance = self.tokenBalanceLamps else {
            return
        }
        
        let errorMessage: String? = nil
        Network.shared.sellToken(
            tokenId: tokenId, amount: String(balance), tokenPrice: String(price)
        ) { result in
            switch result {
            case .success:
                self.purchaseData = nil
            case .failure(let error):
                print("Error selling tokens: \(error)")
            }
            completion(result)
        }

        Network.shared.recordClientEvent(
            event: ClientEvent(
                eventName: "sell_tokens",
                source: "token_model",
                metadata: [
                    ["sell_amount": balance],
                    ["token_id": tokenId],
                ],
                errorDetails: errorMessage
            )
        ) { result in
            switch result {
            case .success:
                print("Successfully recorded buy event")
            case .failure(let error):
                print("Failed to record buy event: \(error)")
            }
        }
    }

    private func startTimer() {
        stopTimer() // Ensure any existing timer is invalidated
        self.initialTime = Date()
        self.elapsedSeconds = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds = Date().timeIntervalSince(self.initialTime)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
