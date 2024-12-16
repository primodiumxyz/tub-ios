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
    
    @Published var userId: String?
    @Published var walletState: EmbeddedWalletState = .notCreated
    @Published var walletAddress: String?
    
    @Published var initializingUser: Bool = false
    
    @Published var usdcBalance: Int? = nil
    @Published var initialTime = Date()
    @Published var elapsedSeconds: TimeInterval = 0
    
    @Published var tokenPortfolio: [String] = []
    @Published var tokenData: [String: TokenData] = [:]
    
    private var timer: Timer?

    @Published var initialPortfolioBalance: Double? = nil
    
    var portfolioBalanceUsd : Double? {
        guard let usdcBalance else { return nil }
        let usdcBalanceUsd = SolPriceModel.shared.usdcToUsd(usdc: usdcBalance)
        let tokenValue = self.tokenPortfolio.reduce(0.0) { total, key in
              if let token = tokenData[key] {
                let price = token.liveData?.priceUsd ?? 0
                let balance = Double(token.balanceToken)
                let decimals = Double(token.metadata.decimals)
                return total + (price * balance / pow(10, decimals))
              }
              return total
            }
        return usdcBalanceUsd + tokenValue
    }
    
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
            async let usdcBalanceTask : () = fetchUsdcBalance()
            async let portfolioTask : () = refreshPortfolio()
            let _ = try await (usdcBalanceTask, portfolioTask)
            
            await MainActor.run {
                self.initialPortfolioBalance = self.portfolioBalanceUsd
            }

            startPollingUsdcBalance()
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
    

    /* -------------------------------------------------------------------------- */
    /*                          Token Data and Portfolio                          */
    /* -------------------------------------------------------------------------- */

    public func refreshPortfolio() async throws {
        let tokenBalances = try await Network.shared.getAllTokenBalances()
        
        let tokenMints = Array(tokenBalances.keys)
        let tokenMetadata = try await fetchBulkTokenMetadata(tokenMints: tokenMints)
        let tokenLiveData = try await fetchBulkTokenLiveData(tokenMints: tokenMints)
        
        for mint in tokenMints {
            if mint == USDC_MINT {
                continue
            }
            await updateTokenData(mint: mint, balance: tokenBalances[mint], metadata: tokenMetadata[mint], liveData: tokenLiveData[mint])
        }
    }

    public func refreshBulkTokenData(tokenMints: [String], withBalances: Bool = false) async throws {
        let balances = withBalances ? try await Network.shared.getAllTokenBalances() : nil
        let tokenMetadata = try await fetchBulkTokenMetadata(tokenMints: tokenMints)
        let tokenLiveData = try await fetchBulkTokenLiveData(tokenMints: tokenMints)
        
        for mint in tokenMints {
            if mint == USDC_MINT {
                continue
            }
            await updateTokenData(mint: mint, balance: balances?[mint], metadata: tokenMetadata[mint], liveData: tokenLiveData[mint])
        }
    }
    
    public func refreshTokenData(tokenMint: String) async {
        do {
            let balanceData = try await Network.shared.getTokenBalance(tokenMint: tokenMint)

            let tokenMetadata = try await fetchTokenMetadata(tokenMint: tokenMint)
            let tokenLiveData = try await fetchTokenLiveData(tokenMint: tokenMint)

            await updateTokenData(mint: tokenMint, balance: balanceData, metadata: tokenMetadata, liveData: tokenLiveData)
        } catch {
            return
        }
    }
    
    @MainActor
    public func updateTokenPrice(mint: String, priceUsd: Double) {
        if mint == USDC_MINT { return }
        guard var tokenData = self.tokenData[mint], var liveData = tokenData.liveData else { return }
        
        liveData.priceUsd = priceUsd
        tokenData.liveData = liveData
        self.tokenData[mint] = tokenData
    }
    
    public func updateTokenData(mint: String, balance: Int? = nil, metadata: TokenMetadata? = nil, liveData: TokenLiveData? = nil) async {
        if mint == USDC_MINT { return }
        
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
            else {  do {newMetadata = try await fetchTokenMetadata(tokenMint: mint)} catch { return }}
            
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

    func fetchTokenMetadata(tokenMint: String) async throws -> TokenMetadata {
        if let data = tokenData[tokenMint] {
            return data.metadata
        }
        let query = GetTokenMetadataQuery(token: tokenMint)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TokenMetadata, Error>) in
            Network.shared.apollo.fetch(query: query) {
                result in switch result {
                    case .success(let response):
                    
                    if response.errors != nil {
                        continuation.resume(throwing: TubError.unknown)
                        return
                    }
                    
                    if let token = response.data?.token_metadata_formatted.first(where: { $0.mint == tokenMint }) {
                        let metadata = TokenMetadata(
                            name: token.name,
                            symbol: token.symbol,
                            description: token.description,
                            imageUri: token.image_uri,
                            externalUrl: token.external_url,
                            decimals: Int(token.decimals ?? 6)
                        )
                        continuation.resume(returning: metadata)
                    }
                    continuation.resume(throwing: TubError.somethingWentWrong(reason: "Metadata not found"))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchBulkTokenMetadata(tokenMints: [String]) async throws -> [String : TokenMetadata] {
        let uncachedTokens = tokenMints.filter { !tokenData.keys.contains($0) }
        let cachedTokens = tokenMints.filter { tokenData.keys.contains($0) }
        
        // Only fetch metadata for uncached tokens
        var ret = [String : TokenMetadata]()
        
        cachedTokens.forEach { ret[$0] = tokenData[$0]!.metadata }
        if uncachedTokens.count > 0 {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                Network.shared.apollo.fetch(
                    query: GetBulkTokenMetadataQuery(tokens: uncachedTokens)
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

    func fetchTokenLiveData(tokenMint: String) async throws -> TokenLiveData {
        let query = GetTokenLiveDataQuery(token: tokenMint)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TokenLiveData, Error>) in
            Network.shared.apollo.fetch(query: query) { result in
                switch result {
                case .success(let response):
                    if response.errors != nil {
                        continuation.resume(throwing: TubError.unknown)
                        return
                    }
                    
                    if let token = response.data?.token_stats_interval_comp.first {
                        let liveData = TokenLiveData(
                            supply: Int(token.token_metadata_supply ?? 0),
                            priceUsd: token.latest_price_usd,
                            stats: IntervalStats(
                                volumeUsd: token.total_volume_usd,
                                trades: Int(token.total_trades),
                                priceChangePct: token.price_change_pct
                            ),
                            recentStats: IntervalStats(
                                volumeUsd: token.recent_volume_usd,
                                trades: Int(token.recent_trades),
                                priceChangePct: token.recent_price_change_pct
                            )
                        )
                        continuation.resume(returning: liveData)
                    } else {
                        continuation.resume(throwing: TubError.somethingWentWrong(reason: "Live data not found"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchBulkTokenLiveData(tokenMints: [String]) async throws -> [String : TokenLiveData] {
        // note: no caching here because we want to fetch the latest data every time

        var ret = [String : TokenLiveData]()
        
        for mint in tokenMints {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                Network.shared.apollo.fetch(
                    query: GetBulkTokenLiveDataQuery(tokens: [mint])
                ) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if graphQLResult.errors != nil {
                            continuation.resume(throwing: TubError.unknown)
                            return
                        }
                        
                        if let tokens = graphQLResult.data?.token_stats_interval_comp {
                            for token in tokens {
                                ret[token.token_mint] = TokenLiveData(
                                    supply: Int(token.token_metadata_supply ?? 0),
                                    priceUsd: token.latest_price_usd,
                                    stats: IntervalStats(volumeUsd: token.total_volume_usd, trades: Int(token.total_trades), priceChangePct: token.price_change_pct),
                                    recentStats: IntervalStats(volumeUsd: token.recent_volume_usd, trades: Int(token.recent_trades), priceChangePct: token.recent_price_change_pct)
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
        }
        return ret
    }
    
    
    private func stopPollingTokenPortfolio() {
        tokenPortfolioTimer?.invalidate()
        tokenPortfolioTimer = nil
    }
    
    /* -------------------------------------------------------------------------- */
    /*                                   Balance                                  */
    /* -------------------------------------------------------------------------- */
    public func fetchUsdcBalance() async throws {
        let balanceUsdc = try await Network.shared.getUsdcBalance()
        await MainActor.run {
            self.usdcBalance = balanceUsdc
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
            self.usdcBalance = 0
            self.initialPortfolioBalance = nil
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
    
    @Published var tokenId: String? = nil
    
    @Published var purchaseData: PurchaseData? = nil
    
    func initToken(tokenId: String) {
        self.tokenId = tokenId
    }
    


    /* -------------------------------------------------------------------------- */
    /*                             Transaction History                            */
    /* -------------------------------------------------------------------------- */

    public func fetchTxs() async throws -> [TransactionData] {
        guard let walletAddress else { return [] }
        let query = GetWalletTransactionsQuery(wallet: walletAddress)
        
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
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
                        }catch {
                            continuation.resume(throwing: error)
                        }
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func processTxs(tokenTransactions:[GetWalletTransactionsQuery.Data.Transaction]) async throws -> [TransactionData] {
        var processedTxs : [TransactionData] = []
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
            let priceUsdc = transaction.token_price_usd
            let decimals = metadata?.decimals ?? 9
            let valueUsdc = Int(transaction.token_amount) * Int(priceUsdc) / Int(pow(10.0,Double(decimals)))
            
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
