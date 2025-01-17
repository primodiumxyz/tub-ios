//
//  AccountBalance.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import SwiftUI

struct AccountBalanceView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var tokenListModel: TokenListModel
    @ObservedObject var userModel: UserModel
    
    var deltaUsd : Double {
        guard let initialBalance  = userModel.initialPortfolioBalance, let currentBalanceUsd = userModel.portfolioBalanceUsd else { return 0 }
        return currentBalanceUsd - initialBalance
    }
    
    private func hasValidTradePair(_ transactions: [TransactionData], for mint: String) -> Bool {
        let tokenTxs = transactions.filter { $0.mint == mint }
        
        // Find the most recent sell
        guard let latestSell = tokenTxs.first(where: { !$0.isBuy }) else {
            return false
        }
        
        // Find the most recent buy that occurred before this sell
        let previousTxs = tokenTxs.filter { $0.date < latestSell.date }
        let validBuy = previousTxs.first { buyTx in
            guard buyTx.isBuy else { return false }
            let txsBetween = tokenTxs.filter { tx in 
                tx.date > buyTx.date && tx.date < latestSell.date && !tx.isBuy
            }
            return txsBetween.isEmpty
        }
        
        return validBuy != nil
    }
    
    var body: some View {
        // Balance Section
        HStack(alignment: .center) {
            if userModel.userId != nil {
                HStack(alignment: .center, spacing: 10) {
                    Text("Your Balance")
                        .font(.sfRounded(size: .base, weight: .semibold))
                        .lineLimit(1)
                    
                    Spacer()
                    if let balanceUsd = userModel.portfolioBalanceUsd {
                        if deltaUsd != 0 {
                            let formattedChange = priceModel.formatPrice(
                                usd: deltaUsd,
                                showSign: true,
                                maxDecimals: 2
                            )
                            
                            Text(formattedChange)
                                .font(.sfRounded(size: .xs, weight: .light))
                                .fontWeight(.bold)
                                .foregroundStyle(deltaUsd >= 0 ? .tubSuccess : .tubError)
                                .opacity(0.7)
                                .frame(height: 10)
                                .padding(0)
                        }
                        
                        let formattedBalance = priceModel.formatPrice(
                            usd: balanceUsd,
                            maxDecimals: 2,
                            minDecimals: 2
                        )
                        
                        Text(formattedBalance)
                            .font(.sfRounded(size: .lg))
                            .fontWeight(.bold)
                            .foregroundStyle(.tubSuccess)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(.tubNeutral, lineWidth: 0.5)
                )
                .frame(maxWidth: .infinity)
                
                if userModel.userId != nil {
                    HStack(spacing: 8) {
                        NavigationLink(destination: AccountView()) {
                            Image("Account")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                        }
                        
                        // Only show share button if there are transactions
                        if let txs = userModel.txs, !txs.isEmpty {
                            let lastTx = txs[0]
                            if hasValidTradePair(txs, for: lastTx.mint) {
                                NavigationLink(destination: ShareView(
                                    tokenName: lastTx.name,
                                    tokenSymbol: lastTx.symbol,
                                    tokenImageUrl: lastTx.imageUri,
                                    tokenMint: lastTx.mint
                                )) {
                                    Image("Share")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                    }
                }
            }
        }
        .foregroundStyle(.tubText)
        .padding(.horizontal, 12)
    }
}

#Preview {
    let userModel = UserModel.shared
    var priceModel : SolPriceModel {
        let model = SolPriceModel.shared
        spoofPriceModelData(model)
        return model
    }
    
    AccountBalanceView(userModel: userModel).environmentObject(priceModel)
}
