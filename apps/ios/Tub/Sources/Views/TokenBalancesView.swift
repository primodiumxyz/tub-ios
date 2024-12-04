//
//  TokenBalancesView.swift
//  Tub
//
//  Created by Henry on 12/4/24.
//

import SwiftUI

struct TokenBalancesView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    @State private var isLoading = false
    @State private var error: Error?
    @State private var tokens: [TokenData] = []

    struct TokenData {
        let mint: String
        let name: String
        let symbol: String
        let imageUri: String
        let balance: Int
        let priceUsd: Double
    }

    private func fetchTokenBalances() {
        guard let wallet = userModel.walletAddress else { return }

        isLoading = true
        error = nil

        Task {
            do {
                let tokenBalances = try await Network.shared.getTokenBalances(address: wallet)
                // Update on main thread since we're modifying UI state
                await MainActor.run {
                    tokens = tokenBalances.map { balance in
                        TokenData(
                            mint: balance.mint.base58EncodedString,
                            name: "",  // These fields aren't available in TokenBalanceData
                            symbol: "",
                            imageUri: "",
                            balance: balance.amountToken,
                            priceUsd: 0  // Price data isn't available in TokenBalanceData
                        )
                    }
                    isLoading = false
                }
            }
            catch {
                await MainActor.run {
                    print("error", error.localizedDescription)
                    self.error = error
                    isLoading = false
                }
            }
        }
    }

    var body: some View {
        VStack {
            PrimaryButton(
                text: "Refresh",
                disabled: isLoading,
                action: fetchTokenBalances
            )
            if isLoading {
                ProgressView()
            }
            else if let error = error {
                ErrorView(error: error) {
                    fetchTokenBalances()
                }
            }
            else if tokens.count == 0 {
                Text("No tokens").foregroundStyle(.tubText)
            }
            else {
                List(tokens, id: \.mint) { token in
                    HStack {
                        Text(token.mint).font(.sfRounded(size: .xxs, weight: .medium))

                        VStack(alignment: .leading) {
                            Text(token.name)
                                .font(.sfRounded(size: .lg, weight: .medium))
                            Text(token.symbol)
                                .font(.sfRounded(size: .sm))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(token.balance)")
                            .font(.sfRounded(size: .lg, weight: .medium))
                    }
                    .padding(.vertical, 4)
                }
            }
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
    TokenBalancesView()
        .environmentObject(priceModel)
        .environmentObject(userModel)
}
