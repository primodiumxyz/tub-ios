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
    
    @Published var pendingTokens: [String] = []
    @Published var tokenQueue: [String] = []
    var currentTokenIndex = -1
    
    @Published var previousTokenModel: TokenModel?
    @Published var nextTokenModel: TokenModel?
    @Published var currentTokenModel: TokenModel
    
    private var hotTokensSubscription: Apollo.Cancellable?
    
    private var currentTokenStartTime: Date?
    
    private var currentTokenId: String? {
        return self.currentTokenModel.tokenId
    }
    
    private var nextTokenId: String? {
        return self.nextTokenModel?.tokenId
    }
    
    var totalTokenCount: Int {
        return self.tokenQueue.count + self.pendingTokens.count
    }
    
    // Make init private
    private init() {
        self.currentTokenModel = TokenModel()
    }
    
    private func initCurrentTokenModel(with tokenId: String) {
        // initialize current model
        self.currentTokenModel.initialize(with: tokenId)
        UserModel.shared.initToken(tokenId: tokenId)
        
    }
    
    private func getNextToken(excluding currentId: String? = nil) -> String? {
        if self.currentTokenIndex < self.tokenQueue.count - 1 {
            return tokenQueue[currentTokenIndex + 1]
        }
        
        let portfolio = UserModel.shared.tokenPortfolio
            let priorityTokenMint = portfolio.first { tokenId in
                tokenId != currentId
            }
            
            if let mint = priorityTokenMint {
                return mint
            }
        
        // If this is the first token (no currentId), return the first non-cooldown token
        var nextToken = self.pendingTokens.first { token in
            !self.tokenQueue.contains { $0 == token } && token != currentId
        }
        if let nextToken { return nextToken }
        
        if self.tokenQueue.count >= 2 {
            repeat { nextToken = self.tokenQueue.randomElement() }
            while currentId != nil && nextToken == currentId
        }
        return nil
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
        newNextTokenModel.preload(with: currentTokenModel.tokenId)
        nextTokenModel = newNextTokenModel
        
        // current
        currentTokenStartTime = Date()
        currentTokenModel = prevModel
        initCurrentTokenModel(with: prevModel.tokenId)
        
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
        newPreviousTokenModel.preload(with: currentTokenModel.tokenId)
        previousTokenModel = newPreviousTokenModel
        
        // current
        currentTokenStartTime = Date()
        if let nextModel = nextTokenModel {
            currentTokenModel = nextModel
            initCurrentTokenModel(with: nextModel.tokenId)
            removePendingToken(nextModel.tokenId)
        }
        else {
            currentTokenModel = TokenModel()
            if let newToken = getNextToken() {
                initCurrentTokenModel(with: newToken)
                removePendingToken(newToken)
            }
        }
    }
    
    func loadNextTokenIntoCurrentTokenPhaseTwo() {
        self.currentTokenIndex += 1
        
        // next
        guard let newToken = getNextToken(excluding: currentTokenModel.tokenId) else {
            return
        }
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
                let hotTokens: [String] = {
                    switch result {
                    case .success(let graphQLResult):
                        if let tokens = graphQLResult.data?.token_stats_interval_comp {
                            let mappedTokens = tokens
                                .map { elem in
                                    elem.token_mint
                                }
                            
                            // Update the current token
                            let currentToken = self.currentTokenModel.tokenId
                            if let updatedToken = mappedTokens.first(where: { $0 == currentToken }) {
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
        self.pendingTokens = self.pendingTokens.filter { $0 != tokenId }
    }
    
    private func updatePendingTokens(_ newTokens: [String]) {
        guard !newTokens.isEmpty else { return }
        
        // Filter out any tokens that are already in the queue
        let unqueuedNewTokens = newTokens.filter { newToken in
            !self.tokenQueue.contains { $0 == newToken }
        }
        
        // Filter out any old tokens that conflict with the new ones
        let uniqueOldTokens = self.pendingTokens.filter { oldToken in
            !unqueuedNewTokens.contains { $0 == oldToken }
        }
        
        self.pendingTokens = Array((unqueuedNewTokens + uniqueOldTokens).prefix(20))
    }
    
    private func initializeTokenQueue() {
        if !self.tokenQueue.isEmpty { return }
        
        // first model
        guard let firstToken = getNextToken() else { return}
        tokenQueue.append(firstToken)
        self.currentTokenIndex = 0
        removePendingToken(firstToken)
        initCurrentTokenModel(with: firstToken)
        
        // second model
        guard let secondToken = getNextToken(excluding: firstToken) else { return }
        tokenQueue.append(secondToken)
        currentTokenStartTime = Date()
        removePendingToken(secondToken)
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
                        ["token_id": currentToken],
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
