//
//  GlobalUserModel.swift
//  Tub
//
//  Created by Henry on 11/14/24.
//

import Combine
import PrivySDK
import SwiftUI
import TubAPI
import CodexAPI

final class UserModel: ObservableObject {
    static let shared = UserModel()
    
    @Published var initializingUser: Bool = false
    @Published var userId: String?
    @Published var walletState: EmbeddedWalletState = .notCreated
    @Published var walletAddress: String?
    
    @Published var balanceUsdc: Int? = nil
    @Published var initialTime = Date()
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var initialBalanceUsdc: Int? = nil
    @Published var balanceChangeUsdc: Int = 0
    
    @Published var tokenPortfolio: [String : TokenData] = [:]
    
    private var timer: Timer?
    
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    
    private init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
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
            default:
                self.userId = nil
                self.walletState = .notCreated
                self.walletAddress = nil
                self.stopTimer()
                self.elapsedSeconds = 0
            }
        }
    }
    
    private func setupWalletStateListener() {
        privy.embeddedWallet.setEmbeddedWalletStateChangeCallback { [weak self] state in
            guard let self = self else { return }
            Task {
                switch state {
                case .connected(let wallets):
                    if let solanaWallet = wallets.first(where: { $0.chainType == .solana }) {
                        await MainActor.run {
                            self.walletAddress = solanaWallet.address
                        }
                        await self.initializeUser()
                        await MainActor.run {
                            self.walletState = state
                        }
                    }
                    else {
                        do {
                            let _ = try await privy.embeddedWallet.createWallet(chainType: .solana)
                        }
                    }
                case .notCreated:
                    do {
                        let _ = try await privy.embeddedWallet.createWallet(chainType: .solana)
                    }
                case .connecting:
                    await MainActor.run {
                        self.walletState = state
                    }
                default:
                    
                    self.logout(skipPrivy: true)
                }
                
            }
        }
    }
    
    func initializeUser() async {
        let timeoutTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.initializingUser = true
            
            // Schedule the timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.initializingUser {
                    self.initializingUser = false
                }
            }
        }
        
        do {
            try await fetchInitialUsdcBalance()
            startPollingUsdcBalance()
            
            try await refreshPortfolio()
            startPollingTokenPortfolio()
        } catch {
            print("error initializing:", error.localizedDescription)
        }
        
        timeoutTask.cancel()  // Cancel timeout if successful
        DispatchQueue.main.async {
            self.initialTime = Date()
            self.initializingUser = false
            print("finished initializing user")
        }
    }
    
    
    private var tokenPortfolioTimer: Timer?
    let PORTFOLIO_POLL_INTERVAL: TimeInterval = 60
    
    private func startPollingTokenPortfolio() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stopPollingTokenPortfolio()  // Ensure any existing timer is invalidated
            
            self.tokenPortfolioTimer = Timer.scheduledTimer(withTimeInterval: self.PORTFOLIO_POLL_INTERVAL, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                Task {
                    try await self.refreshPortfolio()
                }
            }
        }
    }
    
    private func stopPollingTokenPortfolio() {
        tokenPortfolioTimer?.invalidate()
        tokenPortfolioTimer = nil
    }
    
    
    private func refreshPortfolio() async throws {
        guard let walletAddress else { return }
        
        let tokenBalances = try await Network.shared.getTokenBalances(address: walletAddress)
        
        for (mint, balance) in tokenBalances {
            if mint == USDC_MINT {
                continue
            }
            Task {
                try await updateTokenData(mint: mint, balance: balance)
            }
        }
    }
    
    public func refreshTokenData(tokenMint: String) async throws {
        guard let walletAddress else { return }
        let balanceData = try await Network.shared.getTokenBalance(address: walletAddress, tokenMint: tokenMint)
        try await updateTokenData(mint: tokenMint, balance: balanceData)
    }
    
    private func updateTokenData(mint: String, balance: Int) async throws {
        if let tokenData = tokenPortfolio[mint] {
            let newData = TokenData(mint: mint, balanceToken: balance, metadata: tokenData.metadata)
            await MainActor.run {
                self.tokenPortfolio[mint] = newData
            }
        } else {
            let tokenData = try await createTokenMetadata(from: mint)
            let newToken = TokenData(mint: mint, balanceToken: balance, metadata: tokenData)
            await MainActor.run {
                self.tokenPortfolio[mint] = newToken
            }
        }
    }
    
    private func createTokenMetadata(from mint: String) async throws -> TokenMetadata {
        let client = await CodexNetwork.shared.apolloClient
        let query = GetTokenMetadataQuery(address: mint)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TokenMetadata, Error>) in
            client.fetch(query: query) { result in
                switch result {
                case .success(let response):
                    let metadata = TokenMetadata(
                        name: response.data?.token.info?.name,
                        symbol: response.data?.token.info?.symbol,
                        imageUrl: response.data?.token.info?.imageLargeUrl
                    )
                    continuation.resume(returning: metadata)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func fetchUsdcBalance () async throws {
        guard let walletAddress = self.walletAddress else { return }
        if self.initialBalanceUsdc == nil {
            try await self.fetchInitialUsdcBalance()
        } else {
            let balanceUsdc = try await Network.shared.getUsdcBalance(address: walletAddress)
            await MainActor.run {
                self.balanceUsdc = balanceUsdc
                if let initialBalanceUsdc = self.initialBalanceUsdc {
                    self.balanceChangeUsdc = balanceUsdc - initialBalanceUsdc
                }
            }
        }
    }
    
    private func fetchInitialUsdcBalance() async throws {
        guard let walletAddress = self.walletAddress else { return }
        do {
            let balanceUsdc = try await Network.shared.getUsdcBalance(address: walletAddress)
            await MainActor.run {
                self.initialBalanceUsdc = balanceUsdc
                self.balanceUsdc = balanceUsdc
            }
        } catch {
            print("Error fetching initial balance: \(error)")
        }
    }
    
    private var usdcBalanceTimer: Timer?
    private let POLL_INTERVAL: TimeInterval = 10.0  // Set your desired interval here
    
    private func startPollingUsdcBalance() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stopPollingUsdcBalance()  // Ensure any existing timer is invalidated
            
            self.usdcBalanceTimer = Timer.scheduledTimer(withTimeInterval: self.POLL_INTERVAL, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                Task {
                    try await self.fetchUsdcBalance()
                }
            }
        }
    }
    
    private func stopPollingUsdcBalance() {
        usdcBalanceTimer?.invalidate()
        usdcBalanceTimer = nil
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
    
    func logout(skipPrivy: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.userId != nil else { return }
            self.walletState = .notCreated
            self.walletAddress = nil
            self.balanceUsdc = 0
            self.initialBalanceUsdc = nil
            self.balanceChangeUsdc = 0
            self.elapsedSeconds = 0
            self.tokenPortfolio = [:]
            
            self.stopTimer()
            self.stopPollingUsdcBalance()
            self.stopPollingTokenPortfolio()
        }
        if !skipPrivy {
            privy.logout()
            
        }
    }
    
    /* ------------------------------- USER TOKEN ------------------------------- */
    
    @Published var tokenId: String? = nil
    
    @Published var purchaseData: PurchaseData? = nil
    
    func initToken(tokenId: String) {
        self.tokenId = tokenId
        if tokenId != "" {
            Task {
                try! await TxManager.shared.updateTxData(
                    tokenId: tokenId,
                    sellQuantity: SettingsManager.shared.defaultBuyValueUsdc
                )
            }
        }
    }
    
    func buyTokens(buyQuantityUsdc: Int, tokenPriceUsdc: Int) async throws {
        guard let walletAddress else {
            throw TubError.notLoggedIn
        }
        guard let tokenId = self.tokenId, let balanceUsdc = self.balanceUsdc else {
            throw TubError.invalidInput(reason: "No balance")
        }
        
        if buyQuantityUsdc > balanceUsdc {
            throw TubError.insufficientBalance
        }
        
        // TODO: Pull the decimals in the token metadata instead of assuming 9
        let buyQuantityToken = (buyQuantityUsdc / tokenPriceUsdc) * Int(1e9)
        
        var err: (any Error)? = nil
        do {
            try await TxManager.shared.submitTx(walletAddress: walletAddress)
            
            await MainActor.run {
                self.purchaseData = PurchaseData(
                    timestamp: Date(),
                    amountUsdc: buyQuantityUsdc,
                    priceUsdc: Int(tokenPriceUsdc)
                )
            }
        }
        catch {
            err = error
        }
        
        do {
            try await Network.shared.recordClientEvent(
                event: ClientEvent(
                    eventName: "buy_tokens",
                    source: "token_model",
                    metadata: [
                        ["buy_amount": buyQuantityToken],
                        ["price": tokenPriceUsdc],
                        ["token_id": tokenId],
                    ],
                    errorDetails: err?.localizedDescription
                )
            )
            print("Successfully recorded buy event")
        }
        catch {
            print("Failed to record buy event: \(error)")
        }
        
        if let err {
            throw err
        }
    }
    
    func sellTokens(price: Int) async throws {
        guard let walletAddress else {
            throw TubError.notLoggedIn
        }
        
        
        guard let tokenId = self.tokenId, let balanceToken = tokenPortfolio[tokenId]?.balanceToken, balanceToken > 0 else {
            throw TubError.insufficientBalance
        }
        
        var err: (any Error)? = nil
        
        do {
            try await TxManager.shared.submitTx(walletAddress: walletAddress)
            
            await MainActor.run {
                self.purchaseData = nil
            }
        }
        catch {
            err = error
            print("Error selling tokens: \(error)")
        }
        
        do {
            try await Network.shared.recordClientEvent(
                event: ClientEvent(
                    eventName: "sell_tokens",
                    source: "token_model",
                    metadata: [
                        ["sell_amount": balanceToken],
                        ["token_id": tokenId],
                    ],
                    errorDetails: err?.localizedDescription
                )
            )
            print("Successfully recorded sell event")
        }
        catch {
            print("Failed to record sell event: \(error)")
        }
        
        if let err {
            throw err
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
