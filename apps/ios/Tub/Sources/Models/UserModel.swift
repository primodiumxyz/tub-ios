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
    
    @EnvironmentObject private var errorHandler: ErrorHandler
    
    @Published var isLoading: Bool = false
    @Published var userId: String?
    @Published var walletState: EmbeddedWalletState = .notCreated
    @Published var walletAddress: String?
    
    @Published var balanceLamps: Int? = nil
    @Published var initialTime = Date()
    @Published var initialBalanceLamps: Int? = nil
    @Published var balanceChangeLamps: Int = 0
    
    private var accountBalanceSubscription: Apollo.Cancellable?
    
    private init() {
        setupAuthStateListener()
        setupWalletStateListener()
    }
    
    private func setupAuthStateListener() {
        privy.setAuthStateChangeCallback { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .authenticated(let authSession):
                self.userId = authSession.user.id
            case .unauthenticated:
                DispatchQueue.main.async {
                    self.userId = nil
                    self.walletState = .notCreated
                    self.walletAddress = nil
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
                let walletError = NSError(
                    domain: "com.tubapp.wallet", code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to connect wallet."])
                errorHandler.show(walletError)
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
        privy.logout()
    }
}
