//
//  TxManager.swift
//  Tub
//
//  Created by Henry on 11/25/24.
//

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
        do {
            let txData = try await Network.shared.getTxData(buyTokenId: buyTokenId, sellTokenId: sellTokenId, sellQuantity: sellQuantity, slippageBps: 2000)
            let provider = try privy.embeddedWallet.getSolanaProvider(for: walletAddress)
            let signature = try await provider.signMessage(message: txData.transactionMessageBase64)
            let response = try await Network.shared.submitSignedTx(
                txBase64: txData.transactionMessageBase64,
                signature: signature
            )
            let tokenModel = TokenListModel.shared.currentTokenModel
            
            let tokenId = buyTokenId == USDC_MINT ? sellTokenId : buyTokenId
            
            try? await UserModel.shared.refreshBulkTokenData(tokenMints: [USDC_MINT, tokenId], options: .init(withBalances: true, withLiveData: false))
            
            if buyTokenId == USDC_MINT {
                await MainActor.run {
                    tokenModel.purchaseData =  nil
                }
            } else {
                let date = response.timestamp != nil ? Date(timeIntervalSince1970: TimeInterval(response.timestamp! / 1000)) : Date.now
                let priceData = tokenModel.getPrice(at: date)
                await MainActor.run {
                    if let priceUsd = priceData?.priceUsd ?? UserModel.shared.tokenData[tokenId]?.liveData?.priceUsd {
                        
                        let sellQuantityUsd = SolPriceModel.shared.usdcToUsd(usdc: sellQuantity)
                        
                        let decimals = UserModel.shared.tokenData[tokenId]?.metadata.decimals ?? 9
                        let buyQuantityToken = Int((sellQuantityUsd / priceUsd) * pow(10.0,Double(decimals)))
                        
                        tokenModel.purchaseData =  PurchaseData(
                            tokenId: tokenModel.tokenId,
                            timestamp: priceData?.timestamp ?? Date.now,
                            amountToken: buyQuantityToken,
                            priceUsd: priceUsd
                        )
                    }
                }
            }
            
            await MainActor.run { self.submittingTx = false }

        } catch {
            await MainActor.run { self.submittingTx = false }
            throw error
        }
        
        // todo: update swap history in the indexer and fetch the latest sale from a gql query
        
            

    }
}
