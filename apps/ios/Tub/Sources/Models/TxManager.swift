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
    var sellQuantity: Int?
    var lastUpdated = Date()
    let tokenIdUsdc = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    private var currentFetchTask: Task<Void, Error>?

    func updateTxData(purchaseState: PurchaseState? = nil, tokenId: String? = nil, sellQuantity: Int? = nil)
        async throws
    {
        currentFetchTask?.cancel()

        currentFetchTask = Task {
            do {
                try await _updateTxData(purchaseState: purchaseState, tokenId: tokenId, sellQuantity: sellQuantity)
            }
            catch {
                if !Task.isCancelled {
                    throw error
                }
            }
        }
        try await currentFetchTask?.value
    }

    let UPDATE_SECONDS = 60 * 5
    private func _updateTxData(purchaseState: PurchaseState?, tokenId: String?, sellQuantity: Int?) async throws {
        // if nothing is getting updated return without updating
        if Date().timeIntervalSince1970 < lastUpdated.timeIntervalSince1970 + Double(UPDATE_SECONDS)
            && self.purchaseState == (purchaseState ?? self.purchaseState) && self.tokenId == (tokenId ?? self.tokenId)
            && self.sellQuantity == (sellQuantity ?? self.sellQuantity)
        {
            return
        }

        self.tokenId = tokenId ?? self.tokenId
        self.sellQuantity = sellQuantity ?? self.sellQuantity
        self.purchaseState = purchaseState ?? self.purchaseState

        guard let tokenId = self.tokenId, let sellQuantity = self.sellQuantity else { return }

        let buyTokenId = self.purchaseState == .buy ? tokenId : tokenIdUsdc
        let sellTokenId = self.purchaseState == .sell ? tokenId : tokenIdUsdc

        do {
            await MainActor.run {
                self.fetchingTxData = true
            }

            let tx = try await Network.shared.getTxData(
                buyTokenId: buyTokenId,
                sellTokenId: sellTokenId,
                sellQuantity: sellQuantity
            )

            await MainActor.run {
                print("successfully fetched tx data!")
                self.txData = tx
                self.tokenId = self.purchaseState == .buy ? tx.buyTokenId : tx.sellTokenId
                self.sellQuantity = tx.sellQuantity
                self.fetchingTxData = false
            }
        }
        catch {
            print("error updating tx data \(error.localizedDescription)")
        }
    }

    func clearTxData() {
        txData = nil
        sellQuantity = nil
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
            throw TubError.invalidInput(reason: "Missing transaction data")
        }

        let token = self.purchaseState == .sell ? txData.sellTokenId : txData.buyTokenId
        if txData.sellQuantity != self.sellQuantity || token != self.tokenId {
            do {
                try await self.updateTxData(sellQuantity: sellQuantity)
            }
            catch {

            }
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
