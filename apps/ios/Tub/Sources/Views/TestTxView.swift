//
//  TextTxView.swift
//  Tub
//
//  Created by Henry on 11/25/24.
//

import PrivySDK
import SwiftUI

struct TestTxView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var notificationHandler: NotificationHandler
    @EnvironmentObject var userModel: UserModel
    @StateObject var txManager = TxManager.shared

    func handleTxSubmission() {
        Task {
            do {
                guard let walletAddress = userModel.walletAddress else { throw TubError.notLoggedIn }
                try await txManager.submitTx(walletAddress: walletAddress)
            }
            catch {
                notificationHandler.show(error.localizedDescription, type: .error)
            }
        }
    }

    func handleAppear() {
        Task {
            let solTokenId = "So11111111111111111111111111111111111111112"
            do {
                try await txManager.updateTxData(
                    purchaseState: .buy,
                    tokenId: solTokenId,
                    sellQuantity: priceModel.usdToUsdc(usd: 1.0)
                )
            }
            catch {
                notificationHandler.show(error.localizedDescription, type: .error)
            }
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Button(action: handleAppear) {
                Text("Update Tx Data")
            }.padding().background(.blue)
            if let txData = txManager.txData {
                DataRow(title: "Buy Token ID", content: txData.buyTokenId)
                DataRow(title: "Sell Token ID", content: txData.sellTokenId)
                DataRow(title: "Sell Quantity", content: priceModel.formatPrice(lamports: txData.sellQuantity))
                Button(action: handleTxSubmission) {
                    Text("Submit Transaction")
                }.padding().background(.red)
            }
            else {
                Text("no data")
            }
        }.foregroundStyle(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private struct DataRow: View {
        let title: String
        let content: String

        var body: some View {
            VStack {
                HStack {
                    Text(title).font(.sfRounded(weight: .semibold)).frame(maxWidth: 120)
                    Text(content).font(.sfRounded(weight: .light)).frame(maxWidth: .infinity)
                }
                Divider()
            }.frame(maxWidth: .infinity)
        }
    }
}
