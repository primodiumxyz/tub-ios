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

    func updateTxData(purchaseState: PurchaseState? = nil, tokenId: String? = nil, quantity: Int? = nil) throws {
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
    }

    private func _updateTxData(purchaseState: PurchaseState?, tokenId: String?, quantity: Int?) async throws {
        // if nothing is getting updated return without updating
        if self.purchaseState == (purchaseState ?? self.purchaseState) && self.tokenId == (tokenId ?? self.tokenId)
            && self.quantity == (quantity ?? self.quantity)
        {
            return
        }

        self.tokenId = tokenId ?? self.tokenId
        self.quantity = quantity ?? self.quantity
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
            print("error updating tx data \(error.localizedDescription)")
        }
    }

    func clearTxData() {
        txData = nil
        quantity = nil
        tokenId = nil
        purchaseState = .buy
    }

    func submitTx(walletAddress: String) async throws {
        if submittingTx {
            throw TubError.actionInProgress(actionDescription: "Submit transaction")
        }

        // Wait while fetching is in progress, with 2 second timeout
        let startTime = Date()
        while fetchingTxData {
            if Date().timeIntervalSince(startTime) > 2.0 {
                throw TubError.invalidInput(reason: "Timeout waiting for transaction data fetch")
            }
            try await Task.sleep(nanoseconds: 50_000_000)  // 50ms delay
        }

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
