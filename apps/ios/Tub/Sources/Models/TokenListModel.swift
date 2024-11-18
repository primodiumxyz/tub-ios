//
//  TokenListModel.swift
//  Tub
//
//  Created by polarzero on 24/10/2024.
//

import Apollo
import SwiftUI
import TubAPI
import CodexAPI

// Logic for keeping an array of tokens and enabling swiping up (to previously visited tokens) and down (new pumping tokens)
// - The current index in the tokens array is always "last - 1", so we can update "last" to a new random token anytime the subscription is triggered (`updateTokens`)
// - On init, add two random tokens to the array (see `updateTokens`)
// - When swiping down, increase the current index, and push a new random token to the tokens array (that becomes the one that keeps being updated as the sub goes)
// - When swiping up, get back to the previously visited token, pop the last item in the tokens array, so we're again at "last - 1" and "last" gets constantly updated
class TokenListModel: ObservableObject {
    @Published var availableTokens: [Token] = []
    @Published var tokens: [Token] = []
    @Published var previousTokenModel: TokenModel?
    @Published var nextTokenModel: TokenModel?
    @Published var currentTokenModel: TokenModel

    @Published var isLoading = true
    @Published var errorMessage: String?

    private var walletAddress: String

    // Cooldown for not showing the same token too often
    private let TOKEN_COOLDOWN: TimeInterval = 60  // 60 seconds cooldown
    private var recentlyShownTokens: [(id: String, timestamp: Date)] = []

    private var timer: Timer?
    private var currentTokenStartTime: Date?
    private var tokenSubscription: Cancellable?

    init(walletAddress: String) {
        self.walletAddress = walletAddress
        self.currentTokenModel = TokenModel(walletAddress: walletAddress)
    }

    var currentTokenIndex: Int {
        return tokens.count - 2  // last - 1
    }

    var isFirstToken: Bool {
        return currentTokenIndex == 0
    }

    var isNextTokenAvailable: Bool {
        return self.availableTokens.count > 1
    }

    private func initTokenModel() {
        DispatchQueue.main.async {
            self.currentTokenModel.initialize(with: self.tokens[self.currentTokenIndex])
        }
    }

    func createTokenModel() -> TokenModel {
        return TokenModel(walletAddress: walletAddress)
    }

    private func getNextToken(excluding currentId: String? = nil) -> Token? {
        guard !availableTokens.isEmpty else { return nil }

        // Clean up expired cooldowns first
        let now = Date()
        recentlyShownTokens = recentlyShownTokens.filter {
            now.timeIntervalSince($0.timestamp) < TOKEN_COOLDOWN
        }

        // Create a set of tokens to exclude (both cooldown and current)
        let excludedTokenIds = Set(recentlyShownTokens.map { $0.id })
            .union(currentId.map { Set([$0]) } ?? Set())

        // Filter available tokens
        let availableTokensFiltered = availableTokens.filter { token in
            !excludedTokenIds.contains(token.id)
        }

        guard !availableTokensFiltered.isEmpty else {
            // Get all available tokens except current
            let fallbackTokens = availableTokens.filter { token in
                token.id != currentId
            }

            guard !fallbackTokens.isEmpty else { return nil }

            // Sort recently shown by timestamp to find the oldest one that's available
            if let oldestRecent =
                recentlyShownTokens
                .sorted(by: { $0.timestamp < $1.timestamp })  // Sort by oldest first
                .first(where: { recentToken in
                    fallbackTokens.contains(where: { $0.id == recentToken.id })
                })
            {

                // Remove the oldest token from cooldown and add it back with current timestamp
                recentlyShownTokens.removeAll { $0.id == oldestRecent.id }
                recentlyShownTokens.append((id: oldestRecent.id, timestamp: now))

                if let oldestAvailableToken = fallbackTokens.first(where: {
                    $0.id == oldestRecent.id
                }) {
                    return oldestAvailableToken
                }
            }

            // If no match found in cooldown, return a random token
            return fallbackTokens.randomElement()!
        }

        // Get a random token from the filtered list
        let randomIndex = Int.random(in: 0..<availableTokensFiltered.count)
        return availableTokensFiltered[randomIndex]
    }

    // - Set the current token to the next one in line
    // - Update the current token model
    // - Push a new random token to the array for the next swipe
    func loadNextToken() {
        // Record dwell time for current token before switching
        recordTokenDwellTime()

        previousTokenModel = currentTokenModel
        nextTokenModel = createTokenModel()

        // Add current token to cooldown (ensuring uniqueness)
        if let currentToken = tokens[safe: currentTokenIndex] {
            // Remove any existing entry for this token
            recentlyShownTokens.removeAll { $0.id == currentToken.id }
            // Add the token with current timestamp
            recentlyShownTokens.append((id: currentToken.id, timestamp: Date()))
        }

        if let newRandomToken = getNextToken(excluding: tokens[currentTokenIndex].id) {
            tokens.append(newRandomToken)
            initTokenModel()
            // Set start time for new token
            currentTokenStartTime = Date()
        }
    }

    // - Set the current token to the previously visited one
    // - Update the current token model
    // - Pop the last token in the array (swiping down should always be a fresh pumping token)
    func loadPreviousToken() {
        if currentTokenIndex == 0 { return }

        // Record dwell time for current token before switching
        recordTokenDwellTime()

        nextTokenModel = currentTokenModel
        previousTokenModel = createTokenModel()

        // Remove the last token from recently shown when going back
        if let lastToken = tokens.last {
            recentlyShownTokens.removeAll { $0.id == lastToken.id }
        }

        tokens.removeLast()
        initTokenModel()
        // Set start time for new token
        currentTokenStartTime = Date()
    }

    // - Update the last token in the array to a random pumping token (keep it fresh for the next swipe)
    private func updateTokens() {
        guard !availableTokens.isEmpty else { return }

        // If it's initial load, generate two random tokens
        if tokens.isEmpty {
            if let firstToken = getNextToken() {
                tokens.append(firstToken)
                if let secondToken = getNextToken(excluding: firstToken.id) {
                    tokens.append(secondToken)
                    initTokenModel()
                    // Set start time for initial token
                    currentTokenStartTime = Date()
                }
            }
        } else {
            // Only update the last token if we have more available tokens
            if let currentId = tokens[safe: currentTokenIndex]?.id,
                let newToken = getNextToken(excluding: currentId)
            {
                tokens[tokens.count - 1] = newToken
            }
        }
    }

    public func subscribeTokens() async throws {
        // Initial fetch
        try await fetchTokens()

        // Set up timer for 1-second updates
        await MainActor.run {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if !self.fetching {
                    Task {
                        try? await self.fetchTokens()
                    }
                }
            }
        }
    }

    private var fetching = false
    
    private func fetchTokens(setLoading: Bool? = false) async throws {
        let client = await CodexNetwork.shared.apolloClient
        
        if let setLoading = setLoading, setLoading {
            await MainActor.run {
                self.isLoading = true
            }
        }
        
        self.fetching = true
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            client.fetch(query: GetFilterTokensQuery(
                rankingAttribute: .some(.init(TokenRankingAttribute.trendingScore))
            ), cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "TokenListModel", code: 0))
                    return
                }
                
                // Process data in background queue
                DispatchQueue.global(qos: .userInitiated).async {
                    // Prepare data in background
                    let processedData: ([Token], Token?) = {
                        switch result {
                        case .success(let graphQLResult):
                            if let tokens = graphQLResult.data?.filterTokens?.results {
                                let mappedTokens = tokens
                                    .map { elem in
                                        Token(
                                            id: elem?.token?.address,
                                            name: elem?.token?.info?.name,
                                            symbol: elem?.token?.info?.symbol,
                                            description: elem?.token?.info?.description,
                                            imageUri: elem?.token?.info?.imageLargeUrl ?? elem?.token?.info?.imageSmallUrl ?? elem?.token?.info?.imageThumbUrl,
                                            liquidity: Double(elem?.liquidity ?? "0"),
                                            marketCap: Double(elem?.marketCap ?? "0"),
                                            volume: Double(elem?.volume1 ?? "0"),
                                            pairId: elem?.pair?.id,
                                            socials: (discord: elem?.token?.socialLinks?.discord, instagram: elem?.token?.socialLinks?.instagram, telegram: elem?.token?.socialLinks?.telegram, twitter: elem?.token?.socialLinks?.twitter, website: elem?.token?.socialLinks?.website),
                                            uniqueHolders: nil
                                        )
                                    }
                                
                                let currentToken = mappedTokens.first(where: { $0.id == self.currentTokenModel.tokenId })
                                return (mappedTokens, currentToken)
                            }
                            return ([], nil)
                        case .failure(let error):
                            print("Error fetching tokens: \(error.localizedDescription)")
                            return ([], nil)
                        }
                    }()
                    
                    self.fetching = false
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.isLoading = false
                        self.availableTokens = processedData.0
                        self.updateTokens()
                        
                        if let currentToken = processedData.1 {
                            self.currentTokenModel.updateTokenDetails(from: currentToken)
                        }
                    }
                }
                
                continuation.resume()
            }
        }
    }

    // Add cleanup method
    func cleanup() {
        // Record final dwell time before cleanup
        recordTokenDwellTime()

        timer?.invalidate()
        timer = nil
        tokenSubscription?.cancel()
        tokenSubscription = nil
    }

    // Make sure to call cleanup when appropriate
    deinit {
        cleanup()
    }

    func formatTimeElapsed(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60

        if hours > 1 {
            return "past \(hours) hours"
        } else if hours > 0 {
            return "past hour"
        } else if minutes > 1 {
            return "past \(minutes) minutes"
        } else {
            return "past minute"
        }
    }

    // Add this new method after formatTimeElapsed
    private func recordTokenDwellTime() {
        guard let startTime = currentTokenStartTime,
            let currentToken = tokens[safe: currentTokenIndex]
        else { return }

        let dwellTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)  // Convert to milliseconds

        Network.shared.recordClientEvent(
            event: ClientEvent(
                eventName: "token_dwell_time",
                source: "token_list_model",
                metadata: [
                    ["token_id": currentToken.id],
                    ["dwell_time_ms": dwellTimeMs],
                ]
            )
        ) { result in
            switch result {
            case .success:
                print("Successfully recorded token dwell time")
            case .failure(let error):
                print("Failed to record token dwell time: \(error)")
            }
        }
    }
}

// Add a safe subscript extension for arrays if you don't have it already
extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
