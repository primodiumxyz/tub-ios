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
    
    var purchaseState: PurchaseState = .buy
    var tokenId: String?
    var sellQuantity: Int?
    var lastUpdated = Date()
    
    let STALE_TXDATA_SECONDS = 5
    
    private var currentFetchTask: Task<Void, Error>?
    private var fetchStaleTxDataTimer: Timer?
    
    func updateTxData(purchaseState: PurchaseState? = nil, tokenId: String? = nil, sellQuantity: Int? = nil) async throws
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
    
    private func isTxDataStale() -> Bool {
        return Date().timeIntervalSince1970 <= lastUpdated.timeIntervalSince1970 + Double(STALE_TXDATA_SECONDS)
    }
    
    private func startFetchStaleTxDataTimer() {
        DispatchQueue.main.async {
            self.fetchStaleTxDataTimer?.invalidate() // Invalidate any existing timer
            self.fetchStaleTxDataTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.STALE_TXDATA_SECONDS), repeats: true) { [weak self] _ in
                guard let self else { return }
                Task {
                    do {
                        try await self._updateTxData(purchaseState: self.purchaseState, tokenId: self.tokenId, sellQuantity: self.sellQuantity, hard: true)
                    } catch {
                        print("Failed to update transaction data: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func _updateTxData(purchaseState: PurchaseState?, tokenId: String?, sellQuantity: Int?, hard: Bool = false) async throws {
        // if nothing is getting updated return without updating
        if !hard
           && !isTxDataStale()
           && self.purchaseState == (purchaseState ?? self.purchaseState)
           && self.tokenId == (tokenId ?? self.tokenId)
           && self.sellQuantity == (sellQuantity ?? self.sellQuantity)
        {
            return
        }
        
        self.tokenId = tokenId ?? self.tokenId
        self.sellQuantity = sellQuantity ?? self.sellQuantity
        self.purchaseState = purchaseState ?? self.purchaseState
        
        guard let tokenId = self.tokenId, let sellQuantity = self.sellQuantity else { return }
        
        let buyTokenId = self.purchaseState == .buy ? tokenId : USDC_MINT
        let sellTokenId = self.purchaseState == .sell ? tokenId : USDC_MINT
        
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
                self.txData = tx
                self.tokenId = self.purchaseState == .buy ? tx.buyTokenId : tx.sellTokenId
                self.sellQuantity = tx.sellQuantity
                self.fetchingTxData = false
                self.startFetchStaleTxDataTimer() // Start or reset the timer after successful fetch
            }
        }
        catch {
            print("error updating tx data \(error.localizedDescription)")
            await MainActor.run {
                self.fetchingTxData = false
            }
        }
    }
    
    func clearTxData() {
        txData = nil
        sellQuantity = nil
        tokenId = nil
        purchaseState = .buy
        fetchingTxData = false
    }
    
    func submitTx(walletAddress: String) async throws {
        if submittingTx {
            throw TubError.actionInProgress(actionDescription: "Transaction submission")
        }
        
        guard let txData else {
            throw TubError.invalidInput(reason: "Missing transaction data")
        }
        
        // Await fetch completion
        let startTime = Date()
        while fetchingTxData {
            if Date().timeIntervalSince(startTime) > 2.0 {
                throw TubError.invalidInput(reason: "Timeout waiting for transaction data fetch")
            }
            try await Task.sleep(nanoseconds: 50_000_000)  // 50ms delay
        }
        
        // Update tx data if its stale
        let token = self.purchaseState == .sell ? txData.sellTokenId : txData.buyTokenId
        
        if isTxDataStale() || txData.sellQuantity != self.sellQuantity || token != self.tokenId {
            try await self.updateTxData(sellQuantity: sellQuantity)
        }
        
        // Sign and send the tx
        var txError : Error? = nil
        do {
            await MainActor.run {
                self.submittingTx = true
            }
            
            let provider = try privy.embeddedWallet.getSolanaProvider(for: walletAddress)
            let signature = try await provider.signMessage(message: txData.transactionMessageBase64)
            let _ = try await Network.shared.submitSignedTx(
                txBase64: txData.transactionMessageBase64,
                signature: signature
            )
        } catch {
            txError = error
        }

        await MainActor.run {
            self.submittingTx = false
        }
        
        // Update USDC balance & token balance
        Task {
            try! await UserModel.shared.fetchUsdcBalance()
            if let tokenId {
                try! await UserModel.shared.refreshTokenData(tokenMint: tokenId)
            }
        }
        if let txError { throw txError }
    }
}
