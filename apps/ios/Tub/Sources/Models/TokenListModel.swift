//
//  TokenListModel.swift
//  Tub
//
//  Created by polarzero on 24/10/2024.
//

import SwiftUI
import Apollo
import TubAPI

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
    
    private var subscription: Cancellable?
    private var userModel: UserModel

    // Constants for token filtering
    private let INTERVAL: Interval = "30s"
    private let MIN_TRADES: Int = 30
    private let MIN_VOLUME: Int = 1
    private let MINT_BURNT: Bool = true
    private let FREEZE_BURNT: Bool = true

    // Cooldown for not showing the same token too often
    private let TOKEN_COOLDOWN: TimeInterval = 30 // 30 seconds cooldown
    private var recentlyShownTokens: [(id: String, timestamp: Date)] = []
    
    init(userModel: UserModel) {
        self.userModel = userModel
        self.currentTokenModel = TokenModel(walletAddress: userModel.walletAddress)
    }

    var currentTokenIndex: Int {
        return tokens.count - 2 // last - 1
    }

    var isFirstToken: Bool {
        return currentTokenIndex == 0
    }
    
    var isNextTokenAvailable: Bool {
        return self.availableTokens.count > 1
    }

    private func initTokenModel() {
        DispatchQueue.main.async {
            self.currentTokenModel.initialize(with: self.tokens[self.currentTokenIndex].id)
        }
    }

    func createTokenModel() -> TokenModel {
        return TokenModel(walletAddress: userModel.walletAddress)
    }
    
    private func getNextToken(excluding currentId: String? = nil) -> Token? {
        guard !availableTokens.isEmpty else { return nil }
        
        // Clean up expired cooldowns
        let now = Date()
        recentlyShownTokens = recentlyShownTokens.filter { 
            now.timeIntervalSince($0.timestamp) < TOKEN_COOLDOWN 
        }
        
        // Get available tokens excluding those in cooldown and current
        let availableTokensFiltered = availableTokens.filter { token in
            token.id != currentId && 
            !recentlyShownTokens.contains { $0.id == token.id }
        }
        
        guard !availableTokensFiltered.isEmpty else {
            // If no tokens available after filtering, use the original list
            if let fallbackToken = availableTokens.first(where: { token in
                token.id != currentId
            }) {
                recentlyShownTokens.append((id: fallbackToken.id, timestamp: now))
                return fallbackToken
            }
            return nil
        }
        
        // Get the first available token and add it to recently shown
        if let selectedToken = availableTokensFiltered.first {
            recentlyShownTokens.append((id: selectedToken.id, timestamp: now))
            return selectedToken
        }
        
        return nil
    }
    
    // - Set the current token to the next one in line
    // - Update the current token model
    // - Push a new random token to the array for the next swipe
    func loadNextToken() {
        previousTokenModel = currentTokenModel
        nextTokenModel = createTokenModel()
        
        if let newRandomToken = getNextToken(excluding: tokens[currentTokenIndex].id) {
            tokens.append(newRandomToken)
            initTokenModel()
        }
    }

    // - Set the current token to the previously visited one
    // - Update the current token model
    // - Pop the last token in the array (swiping down should always be a fresh pumping token)
    func loadPreviousToken() {
        if currentTokenIndex == 0 { return }
        nextTokenModel = currentTokenModel
        previousTokenModel = createTokenModel()

        tokens.removeLast()
        initTokenModel()
    }
    
    // - Update the last token in the array to a random pumping token (keep it fresh for the next swipe)
    private func updateTokens() {
        guard !availableTokens.isEmpty else { return }
        // If it's initial load, generate two random tokens (current and next)
        if tokens.count == 0 {
            tokens.append(getNextToken()!)
            tokens.append(getNextToken(excluding: tokens[0].id)!)
            initTokenModel()
        } else {
            tokens[tokens.count - 1] = getNextToken(excluding: tokens[currentTokenIndex].id)!
        }
    }

    func fetchTokens() {
        subscription = Network.shared.apollo.subscribe(subscription: SubFilteredTokensIntervalSubscription(
            interval: .some(INTERVAL),
            minTrades: .some(String(MIN_TRADES)),
            minVolume: .some(MIN_VOLUME),
            mintBurnt: .some(MINT_BURNT),
            freezeBurnt: .some(FREEZE_BURNT)
        )) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let error = graphQLResult.errors {
                        print(error)
                        self.errorMessage = "Error: \(error)"
                    }
                    if let tokens = graphQLResult.data?.formatted_tokens_interval {
                        self.availableTokens = tokens.map { elem in
                            Token(id: elem.token_id, mint: elem.mint, name: elem.name ?? "", symbol: elem.symbol ?? "", description: elem.description ?? "", supply: elem.supply ?? 0, decimals: elem.decimals ?? 6, imageUri: elem.uri ?? "", volume: (elem.volume, self.INTERVAL))
                        }

                        self.updateTokens()
                        
                        // Update current token model if the token exists in available tokens
                        if let currentToken = self.availableTokens.first(where: { $0.id == self.currentTokenModel.tokenId }) {
                            self.currentTokenModel.updateTokenDetails(from: currentToken)
                        }
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
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
        } else  {
            return "past minute"
        }
    }
}
