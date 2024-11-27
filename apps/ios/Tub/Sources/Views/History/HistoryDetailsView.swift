//
//  HistoryDetailsView.swift
//  Tub
//
//  Created by yixintan on 10/3/24.
//

import SwiftUI

struct HistoryDetailsView: View {
    @EnvironmentObject private var priceModel: SolPriceModel
    let transaction: Transaction
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 20) {
                    // Token details
                    VStack(alignment: .leading) {
                        Text("Token")
                            .foregroundStyle(.secondary)
                            .font(.sfRounded(size: .sm, weight: .medium))
                        HStack {
                            ImageView(imageUri: transaction.imageUri, size: 40)
                                .cornerRadius(8)

                            Text(transaction.name)
                                .font(.sfRounded(size: .xl, weight: .bold))
                        }
                    }

                    // Transaction number
                    VStack(alignment: .leading) {
                        Text("Transaction number")
                            .foregroundStyle(.secondary)
                            .font(.sfRounded(size: .sm, weight: .medium))
                        Text("#8612373299412")
                            .font(.sfRounded(size: .lg, weight: .regular))
                    }

                    // Quantity
                    VStack(alignment: .leading) {
                        Text("Quantity")
                            .foregroundStyle(.secondary)
                            .font(.sfRounded(size: .sm, weight: .medium))
                        Text(
                            "\(priceModel.formatPrice(lamports:transaction.quantityTokens, showUnit: false)) \(transaction.symbol)"
                        )
                        .font(.sfRounded(size: .lg, weight: .regular))
                    }

                    // Price
                    VStack(alignment: .leading) {
                        Text("Price")
                            .foregroundStyle(.secondary)
                            .font(.sfRounded(size: .sm, weight: .medium))
                        Text(priceModel.formatPrice(usd: transaction.valueUsd))
                            .font(.sfRounded(size: .lg, weight: .regular))
                    }

                    // Date and time of the transaction
                    VStack(alignment: .leading) {
                        Text("Filled")
                            .foregroundStyle(.secondary)
                            .font(.sfRounded(size: .sm, weight: .medium))
                        Text("\(formatDate(transaction.date)) at \(formatTime(transaction.date))")
                            .font(.sfRounded(size: .lg, weight: .regular))
                    }
                }
                .padding(.leading, 10.0)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .navigationTitle(transaction.isBuy ? "Buy Details" : "Sell Details")
        }
    }

}
