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

    private var sellButton: some View {
        Button(action: onSell) {
            Text("Sell")
                .font(.sfRounded(size: .xl, weight: .semibold))
                .foregroundColor(AppColors.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.primaryPink)
                .cornerRadius(30)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 8) {
                Button(action: {
                    showBuySheet = true
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Buy")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .foregroundColor(AppColors.primaryPink)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: 50)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.black)
                    .cornerRadius(26)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .inset(by: 0.5)
                            .stroke(AppColors.primaryPink, lineWidth: 1)
                    )
                }
                sellButton
            }
        }
        .frame(height: 50)
    }
}
