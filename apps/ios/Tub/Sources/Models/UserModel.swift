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
    
    @Published var tokenPortfolio: [String] = []
    @Published var tokenData: [String: TokenData] = [:]

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
                    } else {
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
            
            self.tokenPortfolioTimer = Timer.scheduledTimer(
                withTimeInterval: self.PORTFOLIO_POLL_INTERVAL, repeats: true
            ) { [weak self] _ in
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
        
        await MainActor.run {
            self.tokenPortfolio = tokenBalances.map { $0.mint }
        }
        
        for (mint, balance) in tokenBalances {
            if mint == USDC_MINT {
                continue
            }

            // bulk update token data
            let tokenMetadata = try await fetchTokenMetadata(addresses: self.tokenPortfolio)
            // update token data. since we already have fetched the metadata, this function will always have the metadata cached
            try await updateTokenData(mint: mint, balance: balance, metadata: tokenMetadata[mint])
        }
    }
    
    public func refreshTokenData(tokenMint: String) async throws {
        guard let walletAddress else { return }
        let balanceData = try await Network.shared.getTokenBalance(
            address: walletAddress, tokenMint: tokenMint)
        try await updateTokenData(mint: tokenMint, balance: balanceData)
    }
    
    public func updateTokenData(mint: String, balance: Int? = nil, metadata: TokenMetadata? = nil, liveData: TokenLiveData? = nil) async throws {
        let portfolioContainsToken = self.tokenPortfolio.contains(mint) 
        if let tokenData = tokenData[mint] {
            let newLiveData =  liveData ?? tokenData.liveData
            let newBalance = balance ?? tokenData.balanceToken
            await MainActor.run {
                if newBalance == 0 && portfolioContainsToken {
                    self.tokenPortfolio = self.tokenPortfolio.filter { $0 != mint }
                } else if newBalance > 0 && !portfolioContainsToken {
                    self.tokenPortfolio.append(mint)
                }
                self.tokenData[mint] = TokenData(mint: mint, balanceToken: newBalance, metadata: metadata ?? tokenData.metadata, liveData: newLiveData)
            }
        } else {
            var newMetadata : TokenMetadata?
            if let metadata {newMetadata = metadata }
            else { newMetadata =  try await fetchTokenMetadata(addresses: [mint])[mint]}
            
            guard let newMetadata  else { return }
            
            let tokenData = TokenData(mint: mint, balanceToken: balance ?? 0, metadata: newMetadata, liveData: liveData)
            await MainActor.run {
                if balance ?? 0 > 0 && !portfolioContainsToken {
                    self.tokenPortfolio.append(mint)
                }

                self.tokenData[mint] = tokenData
            }
        }
    }
    
    public func fetchUsdcBalance() async throws {
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
            
            self.usdcBalanceTimer = Timer.scheduledTimer(
                withTimeInterval: self.POLL_INTERVAL, repeats: true
            ) { [weak self] _ in
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
    
    func getLinkedAccounts() -> (
        email: String?, phone: String?, embeddedWallets: [PrivySDK.EmbeddedWallet]
    ) {
        
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
            self.tokenPortfolio = []
            
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
    
    func buyTokens(buyQuantityUsdc: Int, tokenPriceUsdc: Int, tokenPriceUsd: Double) async throws {
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
                    priceUsdc: tokenPriceUsdc
                )
            }
        } catch {
            err = error
        }
        
        do {
            try await Network.shared.recordTokenPurchase(
                tokenMint: tokenId,
                tokenAmount: Double(buyQuantityToken),
                tokenPriceUsd: tokenPriceUsd,
                source: "user_model",
                errorDetails: err?.localizedDescription
            )
            print("Successfully recorded buy event")
        } catch {
            print("Failed to record buy event: \(error)")
        }
        
        if let err {
            throw err
        }
    }
    
    func sellTokens(tokenPriceUsd: Double) async throws {
        guard let walletAddress else {
            throw TubError.notLoggedIn
        }
        
        guard let tokenId = self.tokenId, let balanceToken = tokenData[tokenId]?.balanceToken,
              balanceToken > 0
        else {
            throw TubError.insufficientBalance
        }
        
        var err: (any Error)? = nil
        
        do {
            try await TxManager.shared.submitTx(walletAddress: walletAddress)
            
            await MainActor.run {
                self.purchaseData = nil
            }
        } catch {
            err = error
            print("Error selling tokens: \(error)")
        }
        
        do {
            try await Network.shared.recordTokenSale(
                tokenMint: tokenId,
                tokenAmount: Double(balanceToken),
                tokenPriceUsd: tokenPriceUsd,
                source: "user_model",
                errorDetails: err?.localizedDescription
            )
            print("Successfully recorded sell event")
        } catch {
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
    
    public func fetchTxs() async throws -> [TransactionData] {
        guard let walletAddress else { return [] }
        let query = GetWalletTransactionsQuery(wallet: walletAddress)
        
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    Task {
                        let processedTxs : [TransactionData] = []
                        if let tokenTransactions = graphQLResult.data?.transactions {
                            // Get unique token addresses
                            let uniqueTokens = Set(tokenTransactions.map { $0.token_mint })
                            
                            // Fetch all metadata in one call
                            do {
                                let tokens = try await self.fetchTokenMetadata(addresses: Array(uniqueTokens))
                                
                                var processedTxs: [TransactionData] = []
                                
                                for transaction in tokenTransactions {
                                    guard let date = formatDateString(transaction.created_at)
                                    else {
                                        continue
                                    }
                                    
                                    if abs(transaction.token_amount) == 0 {
                                        continue
                                    }
                                    
                                    let mint = transaction.token_mint
                                    let metadata = tokens[mint]
                                    let isBuy = transaction.token_amount >= 0
                                    let priceUsdc = transaction.token_price_usd
                                    let valueUsdc = Int(transaction.token_amount) * Int(priceUsdc) / Int(1e9)
                                    
                                    let newTransaction = TransactionData(
                                        name: metadata?.name ?? "",
                                        symbol: metadata?.symbol ?? "",
                                        imageUri: metadata?.imageUri ?? "",
                                        date: date,
                                        valueUsdc: -valueUsdc,
                                        quantityTokens: Int(transaction.token_amount),
                                        isBuy: isBuy,
                                        mint: mint
                                    )
                                    
                                    processedTxs.append(newTransaction)
                                }
                            }catch {
                                continuation.resume(throwing: error)
                            }
                            
                        }
                        continuation.resume(returning: processedTxs)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchTokenMetadata(addresses: [String]) async throws -> [String : TokenMetadata] {
        let uncachedTokens = addresses.filter { !tokenData.keys.contains($0) }
        let cachedTokens = addresses.filter { tokenData.keys.contains($0) }

        // Only fetch metadata for uncached tokens
        var ret = [String : TokenMetadata]()
        
        cachedTokens.forEach { ret[$0] = tokenData[$0]!.metadata }
        if uncachedTokens.count > 0 {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                Network.shared.apollo.fetch(
                    query: GetTokensMetadataQuery(tokens: uncachedTokens)
                ) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if graphQLResult.errors != nil {
                            continuation.resume(throwing: TubError.unknown)
                            return
                        }
                        
                        if let tokens = graphQLResult.data?.token_metadata_formatted {
                            for metadata in tokens {
                                ret[metadata.mint] = TokenMetadata(
                                    name: metadata.name,
                                    symbol: metadata.symbol,
                                    description: metadata.symbol,
                                    imageUri: metadata.image_uri,
                                    externalUrl: metadata.external_url,
                                    decimals: Int(metadata.decimals ?? 6)
                                )
                            }
                            continuation.resume()  // Resume without returning a value
                        } else {
                            continuation.resume(throwing: TubError.networkFailure)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        return ret
    }
}
