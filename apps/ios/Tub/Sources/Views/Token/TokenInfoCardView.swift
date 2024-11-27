//
//  TokenInfoCardView.swift
//  Tub
//
//  Created by yixintan on 10/11/24.
//
import SwiftUI

struct TokenInfoCardView: View {
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var userModel: UserModel
    var stats: [StatValue]

    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 60, height: 3)
                    .background(.tubNeutral)
                    .cornerRadius(100)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .center)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(tokenModel.token.name)
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.bottom, 4)

                    ForEach(stats) { stat in
                        VStack(spacing: 10) {
                            HStack(alignment: .center) {
                                Text(stat.title)
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: true, vertical: false)

                                Text(stat.value)
                                    .font(.sfRounded(size: .base, weight: .semibold))
                                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                                    .foregroundStyle(stat.color ?? .tubText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            //divider
                            Rectangle()
                                .foregroundStyle(.clear)
                                .frame(height: 0.5)
                                .background(Color.gray.opacity(0.5))
                        }
                        .padding(.vertical, 6)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("About")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        Text("\(tokenModel.token.description)")
                            .font(.sfRounded(size: .sm, weight: .regular))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .cornerRadius(20)
            }
        }
    }
}
