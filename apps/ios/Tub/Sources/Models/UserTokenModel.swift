//
//  UserTokenModel.swift
//  Tub
//
//  Created by Henry on 11/14/24.
//

import Apollo
import Combine
import SwiftUI
import TubAPI

class UserTokenModel: ObservableObject {
    var tokenId: String = ""
    var walletAddress: String = ""

    @EnvironmentObject private var errorHandler: ErrorHandler

    @Published var balanceLamps: Int = 0

    @Published var purchaseData: PurchaseData? = nil
    
    private var tokenBalanceSubscription: Apollo.Cancellable?

    deinit {
        tokenBalanceSubscription?.cancel()
    }

    init(walletAddress: String, tokenId: String? = nil) {
        self.walletAddress = walletAddress
        if tokenId != nil {
            self.initialize(with: tokenId!)
        }
    }
    
    func initialize(with newTokenId: String, timeframeSecs: Double = CHART_INTERVAL) {
        tokenBalanceSubscription?.cancel()
        subscribeToTokenBalance()
    }

    private func subscribeToTokenBalance() {
        tokenBalanceSubscription?.cancel()

        tokenBalanceSubscription = Network.shared.apollo.subscribe(
            subscription: SubWalletTokenBalanceSubscription(
                wallet: self.walletAddress, token: self.tokenId)
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    self.balanceLamps =
                        graphQLResult.data?.balance.first?.value ?? 0
                case .failure(let error):
                    print("Error updating token balance: \(error.localizedDescription)")
                }
            }
        }
    }

    func buyTokens(
        buyAmountLamps: Int, price: Int, completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
            let tokenAmount = Int(Double(buyAmountLamps) / Double(price) * 1e9)
            var errorMessage: String? = nil

            Network.shared.buyToken(
                tokenId: self.tokenId, amount: String(tokenAmount)
            ) { result in
                switch result {
                case .success:
                    self.purchaseData = PurchaseData(
                        timestamp: Date(),
                        amount: buyAmountLamps,
                        price: price
                    )
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("Error buying tokens: \(error)")
                }
                completion(result)
            }

            Network.shared.recordClientEvent(
                event: ClientEvent(
                    eventName: "buy_tokens",
                    source: "token_model",
                    metadata: [
                        ["token_amount": tokenAmount],
                        ["buy_amount": buyAmountLamps],
                        ["price": price],
                        ["token_id": tokenId],
                    ],
                    errorDetails: errorMessage
                )
            ) { result in
                switch result {
                case .success:
                    print("Successfully recorded buy event")
                case .failure(let error):
                    print("Failed to record buy event: \(error)")
                }
            }
    }

    func sellTokens(completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let errorMessage: String? = nil
        Network.shared.sellToken(
            tokenId: self.tokenId, amount: String(self.balanceLamps)
        ) { result in
            switch result {
            case .success:
                self.purchaseData = nil
            case .failure(let error):
                print("Error selling tokens: \(error)")
            }
            completion(result)
        }

        Network.shared.recordClientEvent(
            event: ClientEvent(
                eventName: "sell_tokens",
                source: "token_model",
                metadata: [
                    ["sell_amount": self.balanceLamps],
                    ["token_id": tokenId],
                ],
                errorDetails: errorMessage
            )
        ) { result in
            switch result {
            case .success:
                print("Successfully recorded buy event")
            case .failure(let error):
                print("Failed to record buy event: \(error)")
            }
        }
    }
}
