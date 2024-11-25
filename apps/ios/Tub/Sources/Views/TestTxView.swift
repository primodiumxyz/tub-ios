//
//  TextTxView.swift
//  Tub
//
//  Created by Henry on 11/25/24.
//

import PrivySDK
import SwiftUI

struct TestTxView: View {
    @State var txData: TxResponse? = nil
    @State var loading = false
    @State var loadingTime = 0.0
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var notificationHandler: NotificationHandler
    @EnvironmentObject var userModel: UserModel

    private func handleTxSubmission(_ tx: TxResponse) {
        Task(priority: .userInitiated) {
            guard let wallet = userModel.walletAddress else {
                notificationHandler.show("Wallet does not exist", type: .error)
                return
            }
            do {
                let provider = try privy.embeddedWallet.getSolanaProvider(for: wallet)
                let signature = try await provider.signMessage(message: tx.transactionBase64)
                print("signature")
                notificationHandler.show("Signature created", type: .success)
            }
            catch {
                await MainActor.run {
                    notificationHandler.show("Error sending transaction", type: .error)
                }
                print(error.localizedDescription)
            }
        }
    }

    func signAndSendSolanaTransaction() async throws {
        // Get the provider for wallet. Wallet chainType MUST be .solana
        //        let signature = try await provider.signMessage(message: message)
    }

    func handleGetTx() async {
        await MainActor.run {
            loading = true
        }
        let startTime = Date()
        do {
            let tx = try await Network.shared.getTestTx()
            await MainActor.run {
                let endTime = Date()
                self.txData = tx
                self.loadingTime = Double(endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970)
                self.loading = false
            }
        }
        catch {
            notificationHandler.show(error.localizedDescription, type: .error)
            print(error.localizedDescription)
        }

    }

    var body: some View {
        VStack(spacing: 10) {
            if loading {
                Text("loading...")
            }
            else if let txData {
                DataRow(title: "Buy Token ID", content: txData.buyTokenId)
                DataRow(title: "Sell Token ID", content: txData.sellTokenId)
                DataRow(title: "Sell Quantity", content: priceModel.formatPrice(lamports: txData.sellQuantity))
                DataRow(title: "Loading Time (s)", content: loadingTime.formatted(.number))
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
