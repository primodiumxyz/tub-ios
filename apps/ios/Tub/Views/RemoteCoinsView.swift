//
//  RemoteCoinsView.swift
//  Tub
//
//  Created by Henry on 10/2/24.
//

import SwiftUI
import Apollo
import TubAPI

struct RemoteCoinsView: View {
    @State private var coins: [Coin] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var subscription: Cancellable?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                } else if coins.isEmpty {
                    Text("No coins found").foregroundColor(.red)
                } else {
//                    CoinView(_coinModel: RemoteCoinModel(tokenId: coins[0].id))
                    List(coins) { coin in
                            HStack {
                                Text(coin.symbol)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(coin.name)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            .navigationTitle("Coins")
            .onAppear(perform: fetchCoins)
        }
    }

    private func fetchCoins() {
        subscription = Network.shared.apollo.subscribe(subscription: GetLatestMockTokensSubscription()) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let tokens = graphQLResult.data?.token {
                        self.coins = tokens.map { elem in Coin(id: elem.id, name: elem.name, symbol: elem.symbol) }
                    }
                case .failure(let error):
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    HomeTabsView()
}



