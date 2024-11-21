//
//  TokenListModel.swift
//  Tub
//
//  Created by polarzero on 24/10/2024.
//

import Apollo
import CodexAPI
import SwiftUI
import TubAPI

// Logic for keeping an array of tokens and enabling swiping up (to previously visited tokens) and down (new pumping tokens)
// - The current index in the tokens array is always "last - 1", so we can update "last" to a new random token anytime the subscription is triggered (`updateTokens`)
// - On init, add two random tokens to the array (see `updateTokens`)
// - When swiping down, increase the current index, and push a new random token to the tokens array (that becomes the one that keeps being updated as the sub goes)
// - When swiping up, get back to the previously visited token, pop the last item in the tokens array, so we're again at "last - 1" and "last" gets constantly updated
class TokenListModel: ObservableObject {

    // Add static shared instance
    static let shared = TokenListModel()

    @Published var availableTokens: [Token] = []
    @Published var tokens: [Token] = []
    @Published var previousTokenModel: TokenModel?
    @Published var nextTokenModel: TokenModel?
    @Published var currentTokenModel: TokenModel
    var userModel: UserModel?  // Make optional since we'll set it after init

    @Published var isLoading = true

    // Cooldown for not showing the same token too often
    private let TOKEN_COOLDOWN: TimeInterval = 60  // 60 seconds cooldown
    private var recentlyShownTokens: [(id: String, timestamp: Date)] = []

    private var timer: Timer?
    private var currentTokenStartTime: Date?
    private var tokenSubscription: Cancellable?

    // Make init private
    private init() {
        self.currentTokenModel = TokenModel()
    }

    // Add method to set user model
    func configure(with userModel: UserModel) {
        self.userModel = userModel
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

    // Update initTokenModel to handle optional userModel
    private func initTokenModel() {
        let token = self.tokens[self.currentTokenIndex]
        self.currentTokenModel.initialize(with: token)
        self.userModel?.initToken(tokenId: token.id)
    }

    private func getNextToken(excluding currentId: String? = nil) -> Token? {
        guard !availableTokens.isEmpty else { return nil }

        // Clean up expired cooldowns (but don't add new ones)
        let now = Date()
        recentlyShownTokens = recentlyShownTokens.filter {
            now.timeIntervalSince($0.timestamp) < TOKEN_COOLDOWN
        }

        // If this is the first token (no currentId), return the first non-cooldown token
        if currentId == nil {
            return availableTokens.first { token in
                !recentlyShownTokens.contains { $0.id == token.id }
            } ?? availableTokens[0]
        }

        // Find the index of the current token
        guard let currentIndex = availableTokens.firstIndex(where: { $0.id == currentId }) else {
            return availableTokens[0]
        }

        // Look for the next available token that's not in cooldown
        for index in (currentIndex + 1)..<availableTokens.count {
            let token = availableTokens[index]
            if !recentlyShownTokens.contains(where: { $0.id == token.id }) {
                return token
            }
        }

        // If we've reached the end, start from beginning
        for index in 0..<currentIndex {
            let token = availableTokens[index]
            if !recentlyShownTokens.contains(where: { $0.id == token.id }) {
                return token
            }
        }

        // If all tokens are in cooldown, get the oldest one
        if let oldestRecent =
            recentlyShownTokens
            .sorted(by: { $0.timestamp < $1.timestamp })
            .first,
            let token = availableTokens.first(where: { $0.id == oldestRecent.id })
        {
            return token
        }

        // Final fallback: return first token
        return availableTokens[0]
    }

    // - Set the current token to the next one in line
    // - Update the current token model
    // - Push a new random token to the array for the next swipe
    func loadNextToken() {
        // Record dwell time for current token before switching
        self.recordTokenDwellTime()

        previousTokenModel = currentTokenModel
        nextTokenModel = TokenModel()

        // Add current token to cooldown here
        if let currentToken = tokens[safe: currentTokenIndex] {
            // Remove any existing entry for this token
            recentlyShownTokens.removeAll { $0.id == currentToken.id }
            // Add the token with current timestamp
            recentlyShownTokens.append((id: currentToken.id, timestamp: Date()))
        }

        if let newToken = getNextToken(excluding: tokens[currentTokenIndex].id) {
            tokens.append(newToken)
            initTokenModel()
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
        previousTokenModel = TokenModel()

        tokens.removeLast()
        initTokenModel()
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
        }
        else {
            // Only update the last token if we have more available tokens
            if let currentId = tokens[safe: currentTokenIndex]?.id,
                let newToken = getNextToken(excluding: currentId)
            {
                tokens[tokens.count - 1] = newToken
            }
        }
    }

    public func startTokenSubscription() async {
        // if we are already subscribed, don't restart it
        if let _ = tokenSubscription { return }
        do {
            try await fetchTokens()

            // Set up timer for 1-second updates
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if !self.fetching {
                    Task {
                        do {
                            try await self.fetchTokens()
                        }
                        catch {
                            print("Error fetching tokens: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        catch {
            print("Error starting token subscription: \(error.localizedDescription)")
        }
    }

    func stopTokenSubscription() {
        // Stop the timer
        timer?.invalidate()
        timer = nil

        // Clear token subscription if it exists
        tokenSubscription?.cancel()
        tokenSubscription = nil
    }

    private var fetching = false

    private func fetchTokens(setLoading: Bool? = false) async throws {
        let client = await CodexNetwork.shared.apolloClient

        self.fetching = true

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            client.fetch(
                query: GetFilterTokensQuery(
                    rankingAttribute: .some(.init(TokenRankingAttribute.trendingScore))
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: TubError.unknown)
                    return
                }

                // Process data in background queue
                DispatchQueue.global(qos: .userInitiated).async {
                    // Prepare data in background
                    let processedData: ([Token], Token?) = {
                        switch result {
                        case .success(let graphQLResult):
                            if let tokens = graphQLResult.data?.filterTokens?.results {
                                let mappedTokens =
                                    tokens
                                    .sorted(by: { Double($0?.volume1 ?? "0") ?? 0 > Double($1?.volume1 ?? "0") ?? 0 })
                                    .map { elem in
                                        Token(
                                            id: elem?.token?.address,
                                            name: elem?.token?.info?.name,
                                            symbol: elem?.token?.info?.symbol,
                                            description: elem?.token?.info?.description,
                                            imageUri: elem?.token?.info?.imageLargeUrl ?? elem?.token?.info?
                                                .imageSmallUrl
                                                ?? elem?.token?.info?.imageThumbUrl,
                                            liquidity: Double(elem?.liquidity ?? "0"),
                                            marketCap: Double(elem?.marketCap ?? "0"),
                                            volume: Double(elem?.volume1 ?? "0"),
                                            pairId: elem?.pair?.id,
                                            socials: (
                                                discord: elem?.token?.socialLinks?.discord,
                                                instagram: elem?.token?.socialLinks?.instagram,
                                                telegram: elem?.token?.socialLinks?.telegram,
                                                twitter: elem?.token?.socialLinks?.twitter,
                                                website: elem?.token?.socialLinks?.website
                                            ),
                                            uniqueHolders: nil
                                        )
                                    }

                                let currentToken = mappedTokens.first(where: {
                                    $0.id == self.currentTokenModel.tokenId
                                })
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
        }
        else if hours > 0 {
            return "past hour"
        }
        else if minutes > 1 {
            return "past \(minutes) minutes"
        }
        else {
            return "past minute"
        }
    }

    // Add this new method after formatTimeElapsed
    private func recordTokenDwellTime() {
        guard let startTime = currentTokenStartTime,
            let currentToken = tokens[safe: currentTokenIndex]
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
}

// Add a safe subscript extension for arrays if you don't have it already
extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
