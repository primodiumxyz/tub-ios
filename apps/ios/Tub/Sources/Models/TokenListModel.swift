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
    private let MIN_TRADES: Int = 10
    private let MIN_INCREASE_PCT: Double = 5.0
    
    init(userModel: UserModel) {
        self.userModel = userModel
        self.currentTokenModel = TokenModel(userId: userModel.userId)
    }

    var currentTokenIndex: Int {
        return tokens.count - 2 // last - 1
    }

    var isFirstToken: Bool {
        return currentTokenIndex == 0
    }

    private func initTokenModel() {
        DispatchQueue.main.async {
            self.currentTokenModel.initialize(with: self.tokens[self.currentTokenIndex].id)
        }
    }

    func createTokenModel() -> TokenModel {
        return TokenModel(userId: userModel.userId)
    }
    
    private func getRandomToken(excluding currentId: String? = nil) -> Token? {
        guard !availableTokens.isEmpty else { return nil }
        guard availableTokens.count > 1 else { return availableTokens[0] }
        var newToken: Token
        repeat {
            let randomIndex = Int.random(in: 0..<availableTokens.count)
            newToken = availableTokens[randomIndex]
        } while newToken.id == currentId

        return newToken
    }
    
    // - Set the current token to the next one in line
    // - Update the current token model
    // - Push a new random token to the array for the next swipe
    func loadNextToken() {
        previousTokenModel = currentTokenModel
        nextTokenModel = createTokenModel()
        
        tokens.append(getRandomToken(excluding: tokens[currentTokenIndex].id)!)
        initTokenModel()
    }

    // - Set the current token to the previously visited one
    // - Update the current token model
    // - Pop the last token in the array (swiping down should always be a fresh pumping token)
    func loadPreviousToken() {
        // TODO: lock swiping up if there is no previous token
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
            tokens.append(getRandomToken()!)
            tokens.append(getRandomToken(excluding: tokens[0].id)!)
            initTokenModel()
        } else {
            tokens[tokens.count - 1] = getRandomToken(excluding: tokens[currentTokenIndex].id)!
        }
    }

    func fetchTokens() {
        subscription = Network.shared.apollo.subscribe(subscription: SubFilteredTokensIntervalSubscription(
            interval: .some(INTERVAL),
            minTrades: String(MIN_TRADES),
            minIncreasePct: String(MIN_INCREASE_PCT)
        )) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let error = graphQLResult.errors {
                        print(error)
                        self.errorMessage = "Error: \(error)"
                    }
                    if let tokens = graphQLResult.data?.get_formatted_tokens_interval {
                        self.availableTokens = tokens.map { elem in
                            Token(id: elem.token_id, name: elem.name, symbol: elem.symbol, mint: elem.mint, decimals: elem.decimals ?? 6, imageUri: nil)
                        }
                        
                        self.updateTokens()
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
