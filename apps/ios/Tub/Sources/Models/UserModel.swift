//
//  GlobalUserModel.swift
//  Tub
//
//  Created by Henry on 11/14/24.
//

import Apollo
import ApolloCombine
import Combine
import PrivySDK
import SwiftUI
import TubAPI

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
        setupAuthStateListener()
        setupWalletStateListener()
    }

    private func setupAuthStateListener() {
        privy.setAuthStateChangeCallback { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .authenticated(let authSession):
                DispatchQueue.main.async {
                    self.userId = authSession.user.id
                }
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
                    DispatchQueue.main.async {
                        self.walletAddress = solanaWallet.address
                    }
                    Task {
                        await self.initializeUser()
                    }
                }
            default:
                break
            }
            DispatchQueue.main.async {
                self.walletState = state
            }
        }
    }

    func initializeUser() async {
        let timeoutTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.error = nil
            self.isLoading = true

            // Schedule the timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.isLoading {
                    self.isLoading = false
                }
            }
        }

        do {
            try await fetchInitialBalance()
            subscribeToAccountBalance()
            if let walletAddress, let tokenId {
                subscribeToTokenBalance(walletAddress: walletAddress, tokenId: tokenId)
            }
            timeoutTask.cancel()  // Cancel timeout if successful
            DispatchQueue.main.async {
                self.initialTime = Date()
                self.isLoading = false
            }
        }
        catch {
            timeoutTask.cancel()  // Cancel timeout if there's an error
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error
            }
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
                    continuation.resume(
                        throwing: NSError(
                            domain: "UserModel",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Self is nil"]
                        )
                    )
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
                wallet: walletAddress
            )
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let graphQLResult):
                let balance = graphQLResult.data?.balance.first?.value ?? 0
                DispatchQueue.main.async {
                    self.balanceLamps = balance
                    if let initialBalanceLamps = self.initialBalanceLamps {
                        self.balanceChangeLamps = balance - initialBalanceLamps
                    }
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.userId != nil else { return }
            self.walletState = .notCreated
            self.walletAddress = nil
            self.balanceLamps = 0
            self.initialBalanceLamps = nil
            self.balanceChangeLamps = 0
            self.stopTimer()
            self.elapsedSeconds = 0
            privy.logout()
        }
    }

    /* ------------------------------- USER TOKEN ------------------------------- */

    @Published var tokenId: String? = nil

    @Published var tokenBalanceLamps: Int? = nil

    @Published var purchaseData: PurchaseData? = nil

    private var tokenBalanceSubscription: Apollo.Cancellable?

    func initToken(tokenId: String) {
        self.tokenId = tokenId
        guard let walletAddress else {
            return
        }

        subscribeToTokenBalance(walletAddress: walletAddress, tokenId: tokenId)
    }

    private func subscribeToTokenBalance(walletAddress: String, tokenId: String) {
        tokenBalanceSubscription?.cancel()

        tokenBalanceSubscription = Network.shared.apollo.subscribe(
            subscription: SubWalletTokenBalanceSubscription(
                wallet: walletAddress,
                token: tokenId
            )
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    let tokenBalanceLamps =
                        graphQLResult.data?.balance.first?.value ?? 0
                    self.tokenBalanceLamps = tokenBalanceLamps
                case .failure(let error):
                    print("Error updating token balance: \(error.localizedDescription)")
                }
            }
        }
    }
    func buyTokens(
        buyAmountLamps: Int,
        priceLamps: Int,
        priceUsd: Double,
        completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        guard let tokenId = self.tokenId, let balance = self.balanceLamps else {
            completion(
                .failure(
                    NSError(domain: "UserModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                )
            )
            return
        }

        var errorMessage: String? = nil

        if buyAmountLamps > balance {
            print("buyAmountLamps: \(buyAmountLamps), balance: \(balance)")
            errorMessage = "Insufficient balance"
            completion(
                .failure(
                    NSError(domain: "UserModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Insufficient balance"])
                )
            )
            return
        }

        let tokenAmount = Int(Double(buyAmountLamps) / Double(priceLamps) * 1e9)

        Network.shared.buyToken(
            tokenId: tokenId,
            amount: String(tokenAmount),
            tokenPrice: String(priceLamps)
        ) { result in
            Task {
                switch result {
                case .success:
                    await MainActor.run {
                        self.purchaseData = PurchaseData(
                            timestamp: Date(),
                            amount: buyAmountLamps,
                            price: priceLamps
                        )
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("Error buying tokens: \(error)")
                }
                completion(result)
            }
        }

        Network.shared.recordClientEvent(
            event: ClientEvent(
                eventName: "buy_tokens",
                source: "token_model",
                metadata: [
                    ["buy_amount": buyAmountLamps],
                    ["price": priceLamps],
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
            tokenId: tokenId,
            amount: String(balance),
            tokenPrice: String(price)
        ) {
            result in
            Task {
                switch result {
                case .success:
                    await MainActor.run {
                        self.purchaseData = nil
                    }
                case .failure(let error):
                    print("Error selling tokens: \(error)")
                }
                completion(result)
            }
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
                print("Successfully recorded sell event")
            case .failure(let error):
                print("Failed to record sell event: \(error)")
            }
        }
    }

    private func startTimer() {
        stopTimer()  // Ensure any existing timer is invalidated
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
