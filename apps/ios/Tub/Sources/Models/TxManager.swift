//
//  TxManager.swift
//  Tub
//
//  Created by Henry on 11/25/24.
//

import PrivySDK
import SwiftUI

final class TxManager: ObservableObject {
    static let shared = TxManager()

    @Published var txData: TxData?

    @Published var fetchingTxData: Bool = false
    @Published var submittingTx: Bool = false
    @Published var txs: [String] = []

    var purchaseState: PurchaseState = .buy
    var tokenId: String?
    var quantity: Int?
    let tokenIdUsdc = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    private var currentFetchTask: Task<Void, Error>?

    func updateTxData(purchaseState: PurchaseState?, tokenId: String?, quantity: Int?) async throws {
        currentFetchTask?.cancel()

        currentFetchTask = Task {
            do {
                try await _updateTxData(purchaseState: purchaseState, tokenId: tokenId, quantity: quantity)
            }
            catch {
                if !Task.isCancelled {
                    throw error
                }
            }
        }

        try await currentFetchTask?.value
    }

    private func _updateTxData(purchaseState: PurchaseState?, tokenId: String?, quantity: Int?) async throws {
        self.tokenId = tokenId ?? self.tokenId
        self.quantity = quantity ?? quantity
        self.purchaseState = purchaseState ?? self.purchaseState

        guard let tokenId = self.tokenId, let quantity = self.quantity else { return }

        let buyTokenId = purchaseState == .buy ? tokenId : tokenIdUsdc
        let sellTokenId = purchaseState == .sell ? tokenId : tokenIdUsdc

        do {
            await MainActor.run {
                self.fetchingTxData = true
            }

            let tx = try await Network.shared.getTxData(
                buyTokenId: buyTokenId,
                sellTokenId: sellTokenId,
                sellQuantity: quantity
            )

            await MainActor.run {
                self.txData = tx
                self.fetchingTxData = false
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }

    func clearTxData() {
        txData = nil
        quantity = nil
        tokenId = nil
        purchaseState = .buy
    }

    func submitTx(walletAddress: String) async throws {
        guard let txData else {
            throw TubError.invalidInput(reason: "Missing required fields")
        }

        do {
            let provider = try privy.embeddedWallet.getSolanaProvider(for: walletAddress)
            let signature = try await provider.signMessage(message: txData.transactionBase64)
            let res = try await Network.shared.submitSignedTx(txBase64: txData.transactionBase64, signature: signature)
            await MainActor.run {
                txs.append(res.txId)
            }
        }
        catch {
            print(error.localizedDescription)
            throw error
        }
    }

}
