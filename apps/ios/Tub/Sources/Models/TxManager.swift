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
    
    @Published var submittingTx: Bool = false
    
    func buyToken(tokenId: String, buyAmountUsdc: Int, tokenPriceUsdc: Int? = nil) async throws {
        guard let usdcBalance = UserModel.shared.usdcBalance, buyAmountUsdc <= usdcBalance else {
            throw TubError.insufficientBalance
        }
        var err: (any Error)? = nil
        do {
            try await submitTx(buyTokenId: tokenId, sellTokenId: USDC_MINT, sellQuantity: buyAmountUsdc)
        } catch {
            err = error
        }
        
        if let tokenPriceUsdc {
            Task {
                let decimals = UserModel.shared.tokenData[tokenId]?.metadata.decimals ?? 9
                let buyQuantityToken = (buyAmountUsdc / tokenPriceUsdc) * Int(pow(10.0,Double(decimals)))
                try? await Network.shared.recordTokenPurchase(
                    tokenMint: tokenId,
                    tokenAmount: Double(buyQuantityToken),
                    tokenPriceUsd: SolPriceModel.shared.usdcToUsd(usdc: tokenPriceUsdc),
                    source: "user_model",
                    errorDetails: err?.localizedDescription
                )
            }
        }
        
        if let err { throw err }
    }
    
    func sellToken(tokenId: String, tokenPriceUsd: Double? = nil) async throws {
        guard let balanceToken = UserModel.shared.tokenData[tokenId]?.balanceToken, balanceToken > 0 else {
            throw TubError.insufficientBalance
        }
        
        var err: (any Error)? = nil
        do {
            try await submitTx(buyTokenId: USDC_MINT, sellTokenId: tokenId, sellQuantity: balanceToken)
        } catch {
            err = error
        }
        
        if let tokenPriceUsd {
            Task {
                try? await Network.shared.recordTokenSale(
                    tokenMint: tokenId,
                    tokenAmount: Double(balanceToken),
                    tokenPriceUsd: tokenPriceUsd,
                    source: "user_model",
                    errorDetails: err?.localizedDescription
                )
            }
        }
        if let err { throw err }
    }
    
    func submitTx(buyTokenId: String, sellTokenId: String, sellQuantity: Int) async throws {
        guard let walletAddress = UserModel.shared.walletAddress else {
            throw TubError.notLoggedIn
        }
        
        if submittingTx {
            throw TubError.actionInProgress(actionDescription: "Transaction submission")
        }
        
         await MainActor.run {
                self.submittingTx = true
         }
            
        // Update tx data if its stale
        
        // Sign and send the tx
        var txError : Error? = nil
        do {
            let txData = try await Network.shared.getTxData(buyTokenId: buyTokenId, sellTokenId: sellTokenId, sellQuantity: sellQuantity, slippageBps: 2000)
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
        let tokenId = buyTokenId == USDC_MINT ? sellTokenId : buyTokenId
        Task {
            try? await UserModel.shared.fetchUsdcBalance()
        }
        if tokenId != "" {
            Task {
                await UserModel.shared.refreshTokenData(tokenMint: tokenId)
            }
        }
        if let txError { throw txError }
    }
}
