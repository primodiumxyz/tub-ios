//
//  AccountBalance.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import SwiftUI

struct AccountBalanceView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var userModel: UserModel
    @ObservedObject var currentTokenModel: TokenModel

    @State private var isExpanded: Bool = false

    var balances: (solBalanceUsd: Double?, tokenBalanceUsd: Double, deltaUsd: Double) {
        let solBalanceUsd: Double? =
            if let balance = userModel.balanceLamps { priceModel.lamportsToUsd(lamports: balance) }
            else { nil }
        let tokenBalanceUsd =
            userModel.tokenBalanceLamps == nil
            ? 0 : Double(userModel.tokenBalanceLamps!) * (currentTokenModel.prices.last?.priceUsd ?? 0) / 1e9

        let deltaUsd = (tokenBalanceUsd) + priceModel.lamportsToUsd(lamports: userModel.balanceChangeLamps)

        return (solBalanceUsd, tokenBalanceUsd, deltaUsd)
    }

    var body: some View {
        VStack(alignment: .center) {
            // Collapsed view

            if !isExpanded {
                VStack {
                    if userModel.userId == nil {
                        EmptyView()
                    }
                    else {
                        HStack {
                            Text("Account Balance")
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundColor(Color.white)

                            Spacer()
                            if let balance = balances.solBalanceUsd {
                                let balanceUsd = priceModel.formatPrice(
                                    usd: balance + balances.tokenBalanceUsd,
                                    maxDecimals: 2,
                                    minDecimals: 2
                                )
                                Text(balanceUsd)
                                    .font(.sfRounded(size: .lg))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.green)
                                    .padding(.trailing)
                                    .frame(height: 20)

                            }
                            else {
                                LoadingBox(width: 80, height: 20)
                            }
                        }
                    }
                }
            }

            // Expanded view
            else {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Account Balance")
                                .font(.sfRounded(size: .sm, weight: .semibold))
                                .foregroundColor(Color.white)

                            HStack {
                                if let balance = balances.solBalanceUsd {
                                    let formattedBalance = priceModel.formatPrice(
                                        usd: balance,
                                        maxDecimals: 2,
                                        minDecimals: 2
                                    )
                                    Text(formattedBalance)
                                        .font(.sfRounded(size: .xl2))
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.white)

                                }

                                let formattedChange = priceModel.formatPrice(
                                    usd: balances.deltaUsd,
                                    showSign: true,
                                    maxDecimals: 2
                                )
                                Text(formattedChange)
                                    .font(.sfRounded(size: .xl2))
                                    .fontWeight(.bold)
                                    .foregroundColor(balances.deltaUsd >= 0 ? Color.green : Color.red)
                            }
                            .font(.sfRounded(size: .sm, weight: .semibold))
                            .foregroundColor(balances.deltaUsd >= -10 ? Color.green : Color.red)
                        }
                        .padding(.horizontal, 5)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }

                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                }
            }
            Divider()
                .frame(width: 340.0, height: 1.0)
                .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.2))
                .padding(.top, 2)
        }
        .padding(10)
        .background(Color.black)
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }

}
