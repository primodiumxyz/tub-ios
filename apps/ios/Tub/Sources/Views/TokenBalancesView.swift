//
//  TokenBalancesView.swift
//  Tub
//
//  Created by Henry on 12/4/24.
//

import CodexAPI
import SwiftUI

struct TokenBalancesView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    @State private var isLoading = false
    @State private var error: Error?
    @State private var tokens: [TokenData] = []

    struct TokenData {
        let address: String
        let balance: Int
        let name: String?
        let symbol: String?
        let imageUrl: String?
    }

    private func createTokenData(from tokenBalance: TokenBalanceData) async throws -> TokenData {
        let client = await CodexNetwork.shared.apolloClient
        let query = GetTokenMetadataQuery(address: tokenBalance.mint)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TokenData, Error>) in
            client.fetch(query: query) { result in
                switch result {
                case .success(let response):
                    let tokenData = TokenData(
                        address: tokenBalance.mint,
                        balance: tokenBalance.amountToken,
                        name: response.data?.token.info?.name,
                        symbol: response.data?.token.info?.symbol,
                        imageUrl: response.data?.token.info?.imageLargeUrl
                    )
                    continuation.resume(returning: tokenData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func processTokenBalances(_ balances: [TokenBalanceData]) async {
        var updatedTokens: [TokenData] = []

        for balance in balances {
            if let tokenData = try? await createTokenData(from: balance) {
                print("new token data:", tokenData)
                updatedTokens.append(tokenData)
            }
        }

        await MainActor.run {
            self.tokens = updatedTokens
        }
    }

    private func fetchTokenBalances() {
        guard let wallet = userModel.walletAddress else { return }

        isLoading = true
        error = nil

        Task {
            do {
                let tokenBalances = try await Network.shared.getTokenBalances(address: wallet)
                print("tokenBalances", tokenBalances)
                await processTokenBalances(tokenBalances)

                print("tokenData", tokenBalances)
                // Update on main thread since we're modifying UI state
                await MainActor.run {
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
                List(tokens, id: \.address) { token in
                    HStack {
                        if let imageUrl = token.imageUrl {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 32, height: 32)
                            }
                        }
                        else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 32, height: 32)
                        }

                        VStack(alignment: .leading) {
                            Text(token.name ?? "")
                                .font(.sfRounded(size: .lg, weight: .medium))
                            Text(token.symbol ?? "")
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
