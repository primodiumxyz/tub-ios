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

    let solTokenId = "So11111111111111111111111111111111111111112"
    let quantity = Int(1e5)
    func handleTxSubmission() {
        Task {
            do {
                try await txManager.buyToken(tokenId: solTokenId, buyAmountUsdc: quantity)
            }
            catch {
                notificationHandler.show(error.localizedDescription, type: .error)
            }
        }
    }

    var body: some View {
        VStack(spacing: 10) {
                DataRow(title: "Buy Token ID", content: solTokenId)
                DataRow(title: "Sell Token ID", content: USDC_MINT)
                DataRow(
                    title: "Sell Quantity",
                    content: priceModel.formatPrice(usdc: quantity)
                )
                
                PrimaryButton(text: "Submit Tx", loading: txManager.submittingTx, action: handleTxSubmission)
        }.foregroundStyle(.tubText).frame(maxWidth: .infinity, maxHeight: .infinity)
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


#Preview {
    @Previewable @StateObject var priceModel = {
        let model = SolPriceModel.shared
        spoofPriceModelData(model)
        return model
    }()

    @Previewable @StateObject var userModel = UserModel.shared
    @Previewable @StateObject var notificationHandler = NotificationHandler()

    TestTxView()
        .environmentObject(priceModel)
        .environmentObject(notificationHandler)
        .environmentObject(userModel)
        .preferredColorScheme(.light)
}
