//
//  GlobalUserModel.swift
//  Tub
//
//  Created by Henry on 11/14/24.
//

import PrivySDK
import SwiftUI
import TubAPI

final class UserModel: ObservableObject {
    static let shared = UserModel()
    
    @Published var userId: String?
    @Published var walletState: EmbeddedWalletState = .notCreated
    @Published var walletAddress: String?
    
    @Published var initializingUser: Bool = false
    
    @Published var initialTime = Date()
    @Published var elapsedSeconds: TimeInterval = 0
    
    @Published var tokenPortfolio: [String] = []
    @Published var tokenData: [String: TokenData] = [:]
    
    private var timer: Timer?
    
    @Published var initialPortfolioBalance: Double? = nil
    
    var portfolioBalanceUsd: Double? {
        let tokenValueUsd = self.tokenPortfolio.reduce(0.0) { total, key in
            if let token = tokenData[key] {
                let price = token.liveData?.priceUsd ?? 0
                let balance = Double(token.balanceToken)
                let decimals = Double(token.metadata.decimals)
                return total + (price * balance / pow(10, decimals))
            }
            return total
        }
        let usdcValueUsd = SolPriceModel.shared.usdcToUsd(usdc: usdcBalance ?? 0)
        return usdcValueUsd + tokenValueUsd
    }
    
    @Published var usdcBalance: Int? = nil
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    
    /* -------------------------------------------------------------------------- */
    /*                               Initialization                               */
    /* -------------------------------------------------------------------------- */
    
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
                    await MainActor.run {
                        self.walletState = state
                    }
                    if privy.authState == .unauthenticated {
                        return
                    }
                    do {
                        let _ = try await privy.embeddedWallet.createWallet(chainType: .solana)
                    } catch {
                    }
                case .connecting:
                    await MainActor.run {
                        self.walletState = state
                    }
                default:
                    await MainActor.run {
                        self.walletState = state
                    }
                    self.logout(skipPrivy: true)
                }
                
            }
        }
    }
    
    func initializeUser() async {
        await MainActor.run {
            self.initializingUser = true
        }
        
        let timeoutTask = DispatchWorkItem { [weak self] in
            guard let self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.initializingUser {
                    self.initializingUser = false
                }
            }
        }
        
        do {
            try await refreshPortfolio()
            
            await MainActor.run {
                self.initialPortfolioBalance = self.portfolioBalanceUsd
            }
            
            startPollingTokenPortfolio()
            
        } catch {
            print("error initializing:", error.localizedDescription)
        }
        
        timeoutTask.cancel()  // Cancel timeout if successful
        
        await MainActor.run {
            self.initialTime = Date()
            self.initializingUser = false
        }
    }
    
    /* -------------------------------------------------------------------------- */
    /*                          Token Data and Portfolio                          */
    /* -------------------------------------------------------------------------- */
    
    private var tokenPortfolioTimer: Timer?
    let PORTFOLIO_POLL_INTERVAL: TimeInterval = 60
    
    private func startPollingTokenPortfolio() {
        self.stopPollingTokenPortfolio()  // Ensure any existing timer is invalidated
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
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
    
    public func refreshPortfolio() async throws {
        let tokenBalances = try await Network.shared.getAllTokenBalances()
        
        let tokenMints = tokenBalances.filter { $0.value > 0 && $0.key != USDC_MINT }.map { $0.key }
        for mint in self.tokenPortfolio {
            if !tokenMints.contains(mint) {
                await updateTokenData(mint: mint, balance: 0)
            }
        }
        
        await MainActor.run {
            // if a token fails to be stored in the tokenData, something went wrong fetching its data so we exclude it from the user's portfolio
            self.tokenPortfolio = tokenMints.filter{ mint in self.tokenData[mint] != nil }
        }
        
        let tokenData = try await fetchBulkTokenFullData(tokenMints: tokenMints)
        for mint in tokenMints + [USDC_MINT] {
            await updateTokenData(mint: mint, balance: tokenBalances[mint], metadata: tokenData[mint]?.metadata, liveData: tokenData[mint]?.liveData)
        }
    }
    
    struct RefreshOptions {
        let withBalances: Bool
        
        init(withBalances: Bool? = nil) {
            self.withBalances = withBalances ?? false
        }
    }
    
    public func refreshBulkTokenData(tokenMints: [String], options: RefreshOptions? = nil)
    async throws
    {
        let withBalances = options?.withBalances ?? false
        async let balances = withBalances ? Network.shared.getAllTokenBalances() : nil
        async let tokenData = fetchBulkTokenFullData(tokenMints: tokenMints)
        
        let (fetchedBalances, fetchedTokenData) = try await (balances, tokenData)
        
        if withBalances, let fetchedBalances {
            let balancesMap = fetchedBalances.map { $0.key }
            for mint in self.tokenPortfolio {
                if !balancesMap.contains(mint) {
                    await updateTokenData(mint: mint, balance: 0)
                }
            }
        }
        
        for mint in tokenMints {
            await updateTokenData(mint: mint, balance: fetchedBalances?[mint], metadata: fetchedTokenData[mint]?.metadata, liveData: fetchedTokenData[mint]?.liveData)
        }
    }
    
    public func refreshTokenData(tokenMint: String) async {
        do {
            async let balanceData = Network.shared.getTokenBalance(tokenMint: tokenMint)
            async let tokenData = fetchTokenFullData(tokenMint: tokenMint)
            
            do {
                let (balance, tokenData) = try await (balanceData, tokenData)
                await updateTokenData(mint: tokenMint, balance: balance, metadata: tokenData.metadata, liveData: tokenData.liveData)
            } catch {
                // Handle error
                print("Error fetching token data: \(error.localizedDescription)")
            }
        } catch {
            return
        }
    }
    
    @MainActor
    public func updateTokenPrice(mint: String, priceUsd: Double) {
        guard var tokenData = self.tokenData[mint], var liveData = tokenData.liveData else { return }
        
        liveData.priceUsd = priceUsd
        tokenData.liveData = liveData
        self.tokenData[mint] = tokenData
    }
    
    public func updateTokenData(
        mint: String,
        balance: Int? = nil,
        metadata: TokenMetadata? = nil,
        liveData: TokenLiveData? = nil
    ) async {
        // Handle USDC separately
        if mint == USDC_MINT {
            guard let balance else { return }
            await MainActor.run {
                self.usdcBalance = balance
            }
            return
        }
        
        let portfolioContainsToken = self.tokenPortfolio.contains(mint)
        
        // Case 1: We have existing data for this token
        if let existingTokenData = self.tokenData[mint] {
            let newBalance = balance ?? existingTokenData.balanceToken
            let newMetadata = metadata ?? existingTokenData.metadata
            let newLiveData = liveData ?? existingTokenData.liveData
            
            await MainActor.run {
                // Update portfolio membership based on balance
                if newBalance == 0 && portfolioContainsToken {
                    self.tokenPortfolio = self.tokenPortfolio.filter { $0 != mint }
                } else if newBalance > 0 && !portfolioContainsToken {
                    self.tokenPortfolio.append(mint)
                }
                
                // Update token data
                self.tokenData[mint] = TokenData(
                    mint: mint,
                    balanceToken: newBalance,
                    metadata: newMetadata,
                    liveData: newLiveData
                )
            }
        }
        // Case 2: No existing data for this token
        else {
            var newMetadata = metadata
            var newLiveData = liveData
            
            // If we don't have token metadata or live data, just fetch both
            if metadata == nil || liveData == nil {
                do {
                    let fetchedData = try await fetchTokenFullData(tokenMint: mint)
                    newMetadata = fetchedData.metadata
                    newLiveData = fetchedData.liveData
                } catch {
                    return
                }
            }
        
            let newTokenData = TokenData(
                mint: mint,
                balanceToken: balance ?? 0,
                metadata: newMetadata!, // if we didn't provide it, it's been fetched
                liveData: newLiveData!
            )
            
            await MainActor.run {
                // Add to portfolio if balance > 0
                if balance ?? 0 > 0 && !portfolioContainsToken {
                    self.tokenPortfolio.append(mint)
                }
                
                // Store the token data
                self.tokenData[mint] = newTokenData
            }
        }
    }
    
    func fetchTokenFullData(tokenMint: String) async throws -> TokenData {
        // Check cache first
        if let data = tokenData[tokenMint] {
            return data
        }

        if let cachedMetadata = TokenMetadata.loadFromCache(for: tokenMint) {
            // Only metadata is cached, still need live data
            let query = GetTokenLiveDataQuery(token: tokenMint)
            return try await withCheckedThrowingContinuation { continuation in
                Network.shared.graphQL.fetch(
                    query: query,
                    cacheTime: QUERY_TOKEN_LIVE_DATA_CACHE_TIME
                ) { result in
                    switch result {
                    case .success(let response):
                        if let token = response.data?.token_rolling_stats_30min.first {
                            let liveData = TokenLiveData(
                                supply: Int(token.supply ?? 0),
                                priceUsd: token.latest_price_usd,
                                stats: IntervalStats(
                                    volumeUsd: token.volume_usd_30m,
                                    trades: Int(token.trades_30m),
                                    priceChangePct: token.price_change_pct_30m
                                ),
                                recentStats: IntervalStats(
                                    volumeUsd: token.volume_usd_1m,
                                    trades: Int(token.trades_1m),
                                    priceChangePct: token.price_change_pct_1m
                                )
                            )
                    
                            let tokenData = TokenData(
                                mint: tokenMint,
                                balanceToken: 0,
                                metadata: cachedMetadata,
                                liveData: liveData
                            )

                            continuation.resume(returning: tokenData)
                        } else {
                            continuation.resume(throwing: TubError.networkFailure)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

        // No cache, fetch everything
        let query = GetTokenFullDataQuery(token: tokenMint)
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.graphQL.fetch(
                query: query,
                cacheTime: QUERY_TOKEN_LIVE_DATA_CACHE_TIME
            ) { result in
                switch result {
                case .success(let response):
                    if let token = response.data?.token_rolling_stats_30min.first {
                        let metadata = TokenMetadata(
                            name: token.name,
                            symbol: token.symbol,
                            description: token.description,
                            imageUri: convertToDwebLink(token.image_uri),
                            externalUrl: token.external_url,
                            decimals: Int(token.decimals),
                            cachedAt: Date()
                        )
                        metadata.saveToCache(for: tokenMint)
                    
                        let liveData = TokenLiveData(
                            supply: Int(token.supply ?? 0),
                            priceUsd: token.latest_price_usd,
                            stats: IntervalStats(
                                volumeUsd: token.volume_usd_30m,
                                trades: Int(token.trades_30m),
                                priceChangePct: token.price_change_pct_30m
                            ),
                            recentStats: IntervalStats(
                                volumeUsd: token.volume_usd_1m,
                                trades: Int(token.trades_1m),
                                priceChangePct: token.price_change_pct_1m
                            )
                        )
                    
                        let tokenData = TokenData(
                            mint: tokenMint,
                            balanceToken: 0,
                            metadata: metadata,
                            liveData: liveData
                        )
                        continuation.resume(returning: tokenData)
                    } else {
                        continuation.resume(throwing: TubError.networkFailure)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchBulkTokenFullData(tokenMints: [String]) async throws -> [String: TokenData] {
        if tokenMints.isEmpty { return [:] }
        var ret = [String: TokenData]()
    
        // Fetch for all tokens - we need fresh live data anyway
        let query = GetBulkTokenFullDataQuery(tokens: tokenMints)
        try await withCheckedThrowingContinuation { continuation in
            Network.shared.graphQL.fetch(
                query: query,
                cacheTime: QUERY_TOKEN_LIVE_DATA_CACHE_TIME
            ) { result in
                switch result {
                case .success(let response):
                    if let tokens = response.data?.token_rolling_stats_30min {
                        for token in tokens {
                            let liveData = TokenLiveData(
                                supply: Int(token.supply ?? 0),
                                priceUsd: token.latest_price_usd,
                                stats: IntervalStats(
                                    volumeUsd: token.volume_usd_30m,
                                    trades: Int(token.trades_30m),
                                    priceChangePct: token.price_change_pct_30m
                                ),
                                recentStats: IntervalStats(
                                    volumeUsd: token.volume_usd_1m,
                                    trades: Int(token.trades_1m),
                                    priceChangePct: token.price_change_pct_1m
                                )
                            )
                            
                            let metadata = TokenMetadata(
                                name: token.name,
                                symbol: token.symbol,
                                description: token.description,
                                imageUri: convertToDwebLink(token.image_uri),
                                externalUrl: token.external_url,
                                decimals: Int(token.decimals),
                                cachedAt: Date()
                            )
                            metadata.saveToCache(for: token.mint)
                        
                            ret[token.mint] = TokenData(
                                mint: token.mint,
                                balanceToken: 0,
                                metadata: metadata,
                                liveData: liveData
                            )
                        }
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: TubError.networkFailure)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        return ret
    }
    
    func fetchBulkTokenMetadata(tokenMints: [String]) async throws -> [String: TokenMetadata] {
        if tokenMints.count == 0 { return [:] }
        var ret = [String: TokenMetadata]()

        tokenMints.forEach { mint in
            if let data = tokenData[mint] {
                ret[mint] = data.metadata
            }
            if let cachedData = TokenMetadata.loadFromCache(for: mint) {
                ret[mint] = cachedData
            }
        }

        let uncachedTokens = tokenMints.filter { ret[$0] == nil }
        
        // Fetch metadata for uncached tokens
        if uncachedTokens.count > 0 {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Void, Error>) in
                Network.shared.graphQL.fetch(
                    query: GetBulkTokenMetadataQuery(tokens: uncachedTokens),
                    cacheTime: QUERY_TOKEN_METADATA_CACHE_TIME
                ) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if graphQLResult.errors != nil {
                            continuation.resume(throwing: TubError.unknown)
                            return
                        }
                        
                        if let tokens = graphQLResult.data?.token_rolling_stats_30min {
                            for metadata in tokens {
                                let tokenMetadata = TokenMetadata(
                                    name: metadata.name,
                                    symbol: metadata.symbol,
                                    description: metadata.symbol,
                                    imageUri: convertToDwebLink(metadata.image_uri),
                                    externalUrl: metadata.external_url,
                                    decimals: Int(metadata.decimals),
                                    cachedAt: Date()  // Set cache timestamp
                                )
                                ret[metadata.mint] = tokenMetadata
                                tokenMetadata.saveToCache(for: metadata.mint)  // Save to cache
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
    
    private func stopPollingTokenPortfolio() {
        tokenPortfolioTimer?.invalidate()
        tokenPortfolioTimer = nil
    }
    
    /* -------------------------------------------------------------------------- */
    /*                               Linked Accounts                              */
    /* -------------------------------------------------------------------------- */
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
            self.initialPortfolioBalance = nil
            self.elapsedSeconds = 0
            self.tokenPortfolio = []
            self.txs = nil
            
            self.stopTimer()
            self.stopPollingTokenPortfolio()
            TokenListModel.shared.initialFetchComplete = false
            self.usdcBalance = 0
            self.tokenData.forEach { (key, val) in
                guard val.balanceToken > 0 else { return }
                var newVal = val
                newVal.balanceToken = 0
                self.tokenData[key] = newVal
            }
            
            TokenListModel.shared.clearQueue()
        }
        if !skipPrivy {
            privy.logout()
            
        }
    }
    
    /* -------------------------------------------------------------------------- */
    /*                             Transaction History                            */
    /* -------------------------------------------------------------------------- */
    
    @Published var txs: [TransactionData]? = nil
    
    private var refreshingTxs: Bool = false
    private var lastFetchedTxsAt: Date = Date.init(timeIntervalSince1970: 0)
    private var TX_STALE_TIME: TimeInterval = 10
    
    public func refreshTxs(hard: Bool = false) async throws {
        
        if refreshingTxs {
            return
        }
        if !hard, Date().timeIntervalSince(lastFetchedTxsAt) < TX_STALE_TIME {
            return
        }
        guard let walletAddress = self.walletAddress else { return }
        await MainActor.run {
            self.refreshingTxs = true
            self.lastFetchedTxsAt = Date()
        }
        
        let query = GetWalletTransactionsQuery(wallet: walletAddress)
        do {
            let newTxs = try await withCheckedThrowingContinuation { continuation in
                Network.shared.graphQL.fetch(query: query, cachePolicy: .fetchIgnoringCacheData, bypassCache: true) { result in
                    switch result {
                    case .success(let graphQLResult):
                        Task {
                            do {
                                guard let transactions = graphQLResult.data?.transactions else {
                                    let ret = [TransactionData]()
                                    return continuation.resume(returning: ret)
                                }
                                let processedTxs = try await self.processTxs(tokenTransactions: transactions)
                                continuation.resume(returning: processedTxs)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    case .failure(let error):
                        print("Error fetching txs", error)
                        continuation.resume(throwing: error)
                    }
                }
            }
            await MainActor.run {
                self.txs = newTxs
                self.refreshingTxs = false
            }
        } catch {
            await MainActor.run {
                self.refreshingTxs = false
            }
            throw error
        }
    }
    
    private func processTxs(tokenTransactions: [GetWalletTransactionsQuery.Data.Transaction])
    async throws -> [TransactionData]
    {
        var processedTxs: [TransactionData] = []
        // Get unique token addresses
        let uniqueTokens = Set(tokenTransactions.map { $0.token_mint })
        
        // Fetch all metadata in one call
        let tokens = try await self.fetchBulkTokenMetadata(tokenMints: Array(uniqueTokens))
        
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
            let priceUsd = transaction.token_price_usd
            let decimals = metadata?.decimals ?? 9
            let valueUsd = transaction.token_amount * priceUsd / pow(10.0, Double(decimals))
            
            let newTransaction = TransactionData(
                name: metadata?.name ?? "",
                symbol: metadata?.symbol ?? "",
                imageUri: convertToDwebLink(metadata?.imageUri) ?? "",
                date: date,
                valueUsd: -valueUsd,
                quantityTokens: Int(transaction.token_amount),
                isBuy: isBuy,
                mint: mint
            )
            
            processedTxs.append(newTransaction)
        }
        return processedTxs
    }
    
    /* -------------------------------------------------------------------------- */
    /*                           Session Duration Timer                           */
    /* -------------------------------------------------------------------------- */
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
