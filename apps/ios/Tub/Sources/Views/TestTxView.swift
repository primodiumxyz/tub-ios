//
//  TextTxView.swift
//  Tub
//
//  Created by Henry on 11/25/24.
//

import PrivySDK
import SwiftUI

struct TestTxView: View {
    @State var txData: TxData? = nil

    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var notificationHandler: NotificationHandler
    @EnvironmentObject var userModel: UserModel

    private func handleTxSubmission(_ tx: TxData) {
        Task(priority: .userInitiated) {
            guard let wallet = userModel.walletAddress else {
                notificationHandler.show("Wallet does not exist", type: .error)
                return
            }
            do {
                let provider = try privy.embeddedWallet.getSolanaProvider(for: wallet)
                let signature = try await provider.signMessage(message: tx.transactionBase64)
                let res = try await Network.shared.submitSignedTx(txBase64: tx.transactionBase64, signature: signature)
                notificationHandler.show("Transaction submitted: \(res.txId)", type: .success)
            }
            catch {
                print(error.localizedDescription)
                await MainActor.run {
                    notificationHandler.show("Error sending transaction", type: .error)
                }
            }
        }
    }

    func handleGetTx() async {
        do {
            let tx = try await Network.shared.getTestTxData()
            await MainActor.run {
                self.txData = tx
            }
        }
        catch {
            notificationHandler.show(error.localizedDescription, type: .error)
        }

    }

    var body: some View {
        VStack(spacing: 10) {
            if let txData {
                DataRow(title: "Buy Token ID", content: txData.buyTokenId)
                DataRow(title: "Sell Token ID", content: txData.sellTokenId)
                DataRow(title: "Sell Quantity", content: priceModel.formatPrice(lamports: txData.sellQuantity))
                Button(action: { handleTxSubmission(txData) }) {
                    Text("Submit Transaction")
                }.padding().background(.red)
            }
            else {
                Text("no data")
            }
        }.foregroundStyle(.white).frame(maxWidth: .infinity, maxHeight: .infinity).onAppear {
            Task {
                await handleGetTx()
            }
        }
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
