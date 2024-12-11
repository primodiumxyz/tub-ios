//
//  TokenListModel.swift
//  Tub
//
//  Created by polarzero on 24/10/2024.
//

import Apollo
import SwiftUI
import TubAPI

// Logic for keeping an array of tokens and enabling swiping up (to previously visited tokens) and down (new pumping tokens)
// - The current index in the tokens array is always "last - 1", so we can update "last" to a new random token anytime the subscription is triggered (`updateTokens`)
// - On init, add two random tokens to the array (see `updateTokens`)
// - When swiping down, increase the current index, and push a new random token to the tokens array (that becomes the one that keeps being updated as the sub goes)
// - When swiping up, get back to the previously visited token, pop the last item in the tokens array, so we're again at "last - 1" and "last" gets constantly updated
final class TokenListModel: ObservableObject {
    static let shared = TokenListModel()
    
    @Published var pendingTokens: [TokenData] = []
    @Published var tokenQueue: [TokenData] = []
    var currentTokenIndex = -1
    
    @Published var previousTokenModel: TokenModel?
    @Published var nextTokenModel: TokenModel?
    @Published var currentTokenModel: TokenModel
    var userModel: UserModel?  // Make optional since we'll set it after init
    
    private var hotTokensSubscription: Apollo.Cancellable?
    
    private var currentTokenStartTime: Date?
    
    private var currentTokenId: String? {
        return self.currentTokenModel.token.id
    }
    
    private var nextTokenId: String? {
        return self.nextTokenModel?.token.id
    }
    
    var totalTokenCount: Int {
        return self.tokenQueue.count + self.pendingTokens.count
    }
    
    // Make init private
    private init() {
        self.currentTokenModel = TokenModel()
    }
    // Add method to set user model
    func configure(with userModel: UserModel) {
        self.userModel = userModel
    }
    
    private func initCurrentTokenModel(with token: TokenData) {
        // initialize current model
        self.currentTokenModel.initialize(with: token)
        self.userModel?.initToken(tokenId: token.id)
        
    }
    
    private func getNextToken(excluding currentId: String? = nil) -> TokenData {
        if self.currentTokenIndex < self.tokenQueue.count - 1 {
            return tokenQueue[currentTokenIndex + 1]
        }
        
        if let userModel {
            let portfolio = userModel.tokenPortfolio
            let priorityTokenMint = portfolio.keys.first { tokenId in
                tokenId != currentId
            }
            
            if let mint = priorityTokenMint, let tokenData = portfolio[mint] {
                return tokenData
            }
        }
        
        // If this is the first token (no currentId), return the first non-cooldown token
        var nextToken = self.pendingTokens.first { token in
            !self.tokenQueue.contains { $0.id == token.id } && token.id != currentId
        }
        if let nextToken { return nextToken }
        
        if self.tokenQueue.count >= 2 {
            repeat { nextToken = self.tokenQueue.randomElement() }
            while currentId != nil && nextToken?.id == currentId
        }
        
        // Final fallback: return first token
        if let nextToken { return nextToken }
        
        return emptyToken
    }
    
    // - Set the current token to the previously visited one
    // - Update the current token model
    // - Pop the last token in the array (swiping down should always be a fresh pumping token)
    func loadPreviousTokenIntoCurrentTokenPhaseOne() -> Bool {
        guard let prevModel = previousTokenModel, currentTokenIndex > 0 else {
            return false
        }
        
        recordTokenDwellTime()
        
        // next
        //	Build up a new TokenModel so that we start from a
        //	known state: no leftover timers and/or subscriptions.
        let newNextTokenModel = TokenModel()
        newNextTokenModel.preload(with: currentTokenModel.token)
        nextTokenModel = newNextTokenModel
        
        // current
        currentTokenStartTime = Date()
        currentTokenModel = prevModel
        initCurrentTokenModel(with: prevModel.token)
        
        return true
    }
    
    func loadPreviousTokenIntoCurrentTokenPhaseTwo() {
        currentTokenIndex -= 1
        
        //previous
        if currentTokenIndex > 0 {
            let previousToken = tokenQueue[currentTokenIndex - 1]
            let newPreviousTokenModel = TokenModel()
            newPreviousTokenModel.preload(with: previousToken)
            self.previousTokenModel = newPreviousTokenModel
        }
        else {
            previousTokenModel = nil
        }
    }
    
    // - Move current to previous
    // - Move next to current and initialize
    // - If current is the end of the array, append a new one and preload it
    func loadNextTokenIntoCurrentTokenPhaseOne() {
        self.recordTokenDwellTime()
        
        // previous
        //	Build up a new TokenModel so that we start from a
        //	known state: no leftover timers and/or subscriptions.
        let newPreviousTokenModel = TokenModel()
        newPreviousTokenModel.preload(with: currentTokenModel.token)
        previousTokenModel = newPreviousTokenModel
        
        // current
        currentTokenStartTime = Date()
        if let nextModel = nextTokenModel {
            currentTokenModel = nextModel
            initCurrentTokenModel(with: nextModel.token)
            removePendingToken(nextModel.token.id)
        }
        else {
            currentTokenModel = TokenModel()
            let newToken = getNextToken()
            initCurrentTokenModel(with: newToken)
            removePendingToken(newToken.id)
        }
    }
    
    func loadNextTokenIntoCurrentTokenPhaseTwo() {
        self.currentTokenIndex += 1
        
        // next
        let newToken = getNextToken(excluding: currentTokenModel.token.id)
        // Add delay before loading next model
        let newModel = TokenModel()
        newModel.preload(with: newToken)
        self.nextTokenModel = newModel
        if self.currentTokenIndex >= tokenQueue.count - 1 {
            tokenQueue.append(newToken)
        }
    }
    
    
    @Published var fetching = false
    public func startTokenSubscription() async {
        do {
            self.hotTokensSubscription = Network.shared.apollo.subscribe(
                subscription: SubTopTokensByVolumeSubscription(
                    interval: .some(HOT_TOKENS_INTERVAL),
                    recentInterval: .some(FILTERING_INTERVAL),
                    minRecentTrades: .some(FILTERING_MIN_TRADES),
                    minRecentVolume: .some(FILTERING_MIN_VOLUME_USD)
                )
            ) { [weak self] result in
                guard let self = self else { return }
                
                // Prepare data in background
                let hotTokens: [TokenData] = {
                    switch result {
                    case .success(let graphQLResult):
                        if let tokens = graphQLResult.data?.token_stats_interval_comp {
                            let mappedTokens = tokens
                                .map { elem in
                                    let metadata = TokenMetadata (
                                    name: elem.token_metadata_name,
                                        symbol: elem.token_metadata_symbol,
                                        description: elem.token_metadata_description,
                                        imageUri: elem.token_metadata_image_uri,
                                        externalUrl: elem.token_metadata_external_url,
                                        decimals: Int(elem.token_metadata_decimals ?? 0)
                                    )
                                    
                                    let liveData = TokenLiveData(
                                         supply: Int(elem.token_metadata_supply ?? 0),
                                        latestPriceUsd: elem.latest_price_usd,
                                        stats: IntervalStats(volumeUsd: elem.total_volume_usd, trades: Int(elem.total_trades), priceChangePct: elem.price_change_pct),
                                        recentStats: IntervalStats(volumeUsd: elem.recent_volume_usd, trades: Int(elem.recent_trades), priceChangePct: elem.recent_price_change_pct)
                                        )

                                    return TokenData(
                                        mint: elem.token_mint,
                                        balanceToken: 0,
                                        metadata: metadata,
                                        liveData: liveData
                                    )
                                }
                            
                            // Update the current token
                            let currentToken = self.currentTokenModel.token
                            if let updatedToken = mappedTokens.first(where: { $0.id == currentToken.id }) {
                                self.currentTokenModel.updateTokenDetails(updatedToken)
                            }
                            
                            return mappedTokens
                        }
                        return []
                    case .failure(let error):
                        print("Error fetching tokens: \(error.localizedDescription)")
                        return []
                    }
                }()
                self.fetching = false
                self.updatePendingTokens(hotTokens)
                if self.tokenQueue.isEmpty {
                    self.initializeTokenQueue()
                }
            }
        }
    }
    
    func stopTokenSubscription() {
        self.hotTokensSubscription?.cancel()
    }
    
    private func removePendingToken(_ tokenId: String) {
        self.pendingTokens = self.pendingTokens.filter { $0.id != tokenId }
    }
    
    private func updatePendingTokens(_ newTokens: [TokenData]) {
        guard !newTokens.isEmpty else { return }
        
        // Filter out any tokens that are already in the queue
        let unqueuedNewTokens = newTokens.filter { newToken in
            !self.tokenQueue.contains { $0.id == newToken.id }
        }
        
        // Filter out any old tokens that conflict with the new ones
        let uniqueOldTokens = self.pendingTokens.filter { oldToken in
            !unqueuedNewTokens.contains { $0.id == oldToken.id }
        }
        
        self.pendingTokens = Array((unqueuedNewTokens + uniqueOldTokens).prefix(20))
    }
    
    private func initializeTokenQueue() {
        if !self.tokenQueue.isEmpty { return }
        
        // first model
        let firstToken = getNextToken()
        tokenQueue.append(firstToken)
        self.currentTokenIndex = 0
        removePendingToken(firstToken.id)
        initCurrentTokenModel(with: firstToken)
        
        // second model
        let secondToken = getNextToken(excluding: firstToken.id)
        tokenQueue.append(secondToken)
        currentTokenStartTime = Date()
        removePendingToken(secondToken.id)
        let nextModel = TokenModel()
        nextModel.preload(with: secondToken)
        self.nextTokenModel = nextModel
    }
    
    // Add this new method after formatTimeElapsed
    private func recordTokenDwellTime() {
        guard let startTime = currentTokenStartTime,
              let currentToken = tokenQueue[safe: currentTokenIndex]
        else { return }
        
        Task {
            let dwellTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)  // Convert to milliseconds
            
            try? await Network.shared.recordClientEvent(
                event: ClientEvent(
                    eventName: "token_dwell_time",
                    source: "token_list_model",
                    metadata: [
                        ["token_id": currentToken.id],
                        ["dwell_time_ms": dwellTimeMs],
                    ]
                )
            )
        }
    }
    
    public func clearQueue() {
        self.tokenQueue = []
        self.pendingTokens = []
        self.currentTokenIndex = -1
        self.previousTokenModel = nil
        self.nextTokenModel = nil
        self.currentTokenModel = TokenModel()
    }
    
    deinit {
        // Record final dwell time before cleanup
        recordTokenDwellTime()
        
        stopTokenSubscription()
    }
}

// Add a safe subscript extension for arrays if you don't have it already
extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
