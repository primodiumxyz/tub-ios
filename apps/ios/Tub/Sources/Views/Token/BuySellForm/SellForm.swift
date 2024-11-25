//
//  SellForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct SellForm: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var tokenModel: TokenModel
    @Binding var showBuySheet: Bool
    var onSell: () async -> Void

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 8) {
                OutlineButton(
                    text: "Buy",
                    textColor: Color("pink"),
                    strokeColor: Color("pink"),
                    backgroundColor: Color(UIColor.systemBackground),
                    action: { showBuySheet = true }
                )

                PrimaryButton(
                    text: "Sell",
                    textColor: Color.white,
                    backgroundColor: Color("pink"),
                    action: {
                        Task {
                            await onSell()
                        }
                    }
                )
            }
        }
        .frame(height: 50)
    }
}
