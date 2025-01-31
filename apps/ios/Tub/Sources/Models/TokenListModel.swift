//
//  TokenListModel.swift
//  Tub
//
//  Created by polarzero on 24/10/2024.
//

import Apollo
import SwiftUI
import TubAPI

/**
 * This class is responsible for managing the token list and enabling swiping up and down to visit previously visited tokens and new pumping tokens.
 * It will manage the token queue, initialization, updating the token list, and polling for hot tokens.
*/
final class TokenListModel: ObservableObject {
    static let shared = TokenListModel()
    
    var currentTokenIndex = -1
    
    @Published var pendingTokens: [String] = []
    @Published var tokenQueue: [String] = []
    
    @Published var previousTokenModel: TokenModel?
    @Published var nextTokenModel: TokenModel?
    @Published var currentTokenModel: TokenModel
    @Published var initialFetchComplete = false
    
    private var hotTokensPollingTimer: Timer?
    
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
        self.currentTokenModel.initialize(with: tokenId)
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
            repeat {
                nextToken = self.tokenQueue.randomElement()
            } while currentId != nil && nextToken == currentId
        }
        return nil
    }
    
    // - Set the current token to the previously visited one
    // - Update the current token model
    // - Pop the last token in the array (swiping down should always be a fresh pumping token)
    
    func canSwipeUp() -> Bool {
        return previousTokenModel != nil && currentTokenIndex > 0 && tokenQueue.count > 1
    }
    
    func canSwipeDown(currentId: String? = nil) -> Bool {
        return getNextToken(excluding: currentId) != nil
    }
    
    func loadPreviousTokenIntoCurrentTokenPhaseOne() -> Bool {
        guard let prevModel = previousTokenModel, canSwipeUp() else {
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
        if currentTokenIndex > 0  {
            
            let previousToken = tokenQueue[currentTokenIndex - 1]
            let newPreviousTokenModel = TokenModel()
            newPreviousTokenModel.preload(with: previousToken)
            self.previousTokenModel = newPreviousTokenModel
        } else {
            previousTokenModel = nil
        }
    }
    
    // - Move current to previous
    // - Move next to current and initialize
    // - If current is the end of the array, append a new one and preload it
    @MainActor
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
        } else {
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
    
    private func getCurrentHotTokens() async throws -> [String] {
        let start = Date()
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<[String], Error>) in
            Network.shared.graphQL.fetch(
                query: GetTopTokensByVolumeQuery(
                    minRecentTrades: .some(FILTERING_MIN_TRADES),
                    minRecentVolume: .some(FILTERING_MIN_VOLUME_USD)
                ),
                cachePolicy: .fetchIgnoringCacheData,
                cacheTime: QUERY_HOT_TOKENS_CACHE_TIME
            ) {
                result in
                switch result {
                case .success(let graphQLResult):
                    if let tokens = graphQLResult.data?.token_rolling_stats_30min {
                        let tokenIds = tokens.map { elem in elem.mint }
                        continuation.resume(returning: tokenIds)
                    } else {
                        if let errors = graphQLResult.errors, errors.count > 0 {
                            continuation.resume(throwing: TubError.somethingWentWrong(reason:  errors[0].description ))
                        } else {
                            continuation.resume(throwing: TubError.somethingWentWrong(reason:  "Could not fetch hot tokens" ) )
                        }
                    }
                case .failure(let error):
                    let end = Date()
                    print("Error fetching initial hot tokens in \(end.timeIntervalSince(start)) seconds")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func pollHotTokens() {
        Task {
            do {
                let hotTokens = try await getCurrentHotTokens()
                await handleHotTokenFetch(hotTokens: hotTokens)
            } catch {
                print("Error polling hot tokens: \(error.localizedDescription)")
            }
        }
    }

    public func startHotTokensPolling() async {
        stopHotTokensPolling()
        pollHotTokens()

        await MainActor.run {
            self.hotTokensPollingTimer = Timer.scheduledTimer(withTimeInterval: HOT_TOKENS_POLLING_INTERVAL, repeats: true) { [weak self] _ in
                self?.pollHotTokens()
            }
        }
    }
    
    func handleHotTokenFetch(hotTokens: [String]) async {
        await self.updatePendingTokens(hotTokens)
        await MainActor.run {
            if self.tokenQueue.isEmpty {
                self.initializeTokenQueue()
            }
        }
    }
    
    func stopHotTokensPolling() {
        self.hotTokensPollingTimer?.invalidate()
        self.hotTokensPollingTimer = nil
    }
    
    @MainActor
    private func removePendingToken(_ tokenId: String) {
        self.pendingTokens = self.pendingTokens.filter { $0 != tokenId }
    }
    
    private func updatePendingTokens(_ newTokens: [String]) async {
        guard !newTokens.isEmpty else {
            if !self.initialFetchComplete { await MainActor.run {self.initialFetchComplete = true} }
            return
        }
        
        // Filter out any tokens that are already in the queue
        let unqueuedNewTokens = newTokens.filter { newToken in
            !self.tokenQueue.contains { $0 == newToken }
        }
        
        // Filter out any old tokens that conflict with the new ones
        let uniqueOldTokens = self.pendingTokens.filter { oldToken in
            !unqueuedNewTokens.contains { $0 == oldToken }
        }
        
        let newTokens = Array((unqueuedNewTokens + uniqueOldTokens))
        let tokens = UserModel.shared.tokenData
        let newTokensToRefresh = newTokens.filter { tokens[$0] == nil }
        if newTokensToRefresh.count > 0 {
            try? await UserModel.shared.refreshBulkTokenData(
                tokenMints: Array(newTokensToRefresh.prefix(3)))
        }
        
        if newTokensToRefresh.count > 3 {
            Task {
                try? await UserModel.shared.refreshBulkTokenData(
                    tokenMints: Array(newTokensToRefresh.suffix(newTokensToRefresh.count - 3)))
            }
        }
        
        await MainActor.run {
            if !self.initialFetchComplete { self.initialFetchComplete = true }
            self.pendingTokens = newTokens
        }
    }
    
    @MainActor
    private func initializeTokenQueue() {
        if !self.tokenQueue.isEmpty { return }
        
        // first model
        guard let firstToken = getNextToken() else { return }
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
            
            try? await Network.shared.recordTokenDwellTime(
                tokenMint: currentToken,
                dwellTimeMs: dwellTimeMs,
                source: "token_list_model",
                errorDetails: nil
            )
        }
    }
    
    @MainActor
    public func clearQueue() {
        self.initialFetchComplete = false
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
        
        stopHotTokensPolling()
    }
}

// Add a safe subscript extension for arrays if you don't have it already
extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
