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
    var onSell: () -> Void

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 8) {
                OutlineButton(
                    text: "Buy",
                    textColor: AppColors.primaryPink,
                    strokeColor: AppColors.primaryPink,
                    backgroundColor: AppColors.black,
                    action: { showBuySheet = true }
                )
                
                PrimaryButton(
                    text: "Sell",
                    textColor: AppColors.white,
                    backgroundColor: AppColors.primaryPink,
                    action: onSell
                )
            }
        }
        .frame(height: 50)
    }
}
