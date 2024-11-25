//
//  TxManager.swift
//  Tub
//
//  Created by Henry on 11/25/24.
//

import PrivySDK
import SwiftUI

class TxManager: ObservableObject {
    @Published var txData: TxData?

    @Published var fetchingTxData: Bool = false
    @Published var submittingTx: Bool = false
    @Published var txs: [String] = []

    var purchaseState: PurchaseState = .buy
    var tokenId: String?
    var quantity: Int?
    let tokenIdUsdc = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"

    func updateTxData(purchaseState: PurchaseState?, tokenId: String?, quantity: String?) async throws {
        let tokenId = tokenId ?? self.tokenId
        let quantity = quantity ?? quantity
        let purchaseState = purchaseState ?? self.purchaseState

        guard let tokenId, let quantity else { return }

        let buyTokenId = purchaseState == .buy ? tokenId : tokenIdUsdc
        let sellTokenId = purchaseState == .sell ? tokenIdUsdc : tokenId
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
        }
    }

}
