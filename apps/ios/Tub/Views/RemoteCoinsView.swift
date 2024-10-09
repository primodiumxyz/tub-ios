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
    @State private var subscription: Cancellable?
    @State private var errorMessage: String?
    @State private var showRegisterView = false
    
    @AppStorage("userId") private var userId: String = ""
    @AppStorage("username") private var username: String = ""

    var body: some View {
        NavigationView {
            VStack {
                AccountView(userId: userId, handleLogout: {
                    userId = ""
                    username = ""
                    showRegisterView = true
                }).frame(height: 200)
                if isLoading {
                    ProgressView()
                } else if coins.isEmpty {
                    Text("No coins found").foregroundColor(.red)
                } else {
                    List(coins) { coin in
                        NavigationLink(destination: CoinView(userId: userId, tokenId: coin.id)) {
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
            }
            .navigationTitle("Coins")
            .onAppear(perform: fetchCoins)
            .fullScreenCover(isPresented: $showRegisterView) {
                RegisterView()
            }
        }
    }

    private func fetchCoins() {
        subscription = Network.shared.apollo.subscribe(subscription: GetLatestMockTokensSubscription()) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    print(graphQLResult)
                    if let tokens = graphQLResult.data?.token {
                        print(tokens)
                        self.coins = tokens.map { elem in Coin(id: elem.id, name: elem.name, symbol: elem.symbol) }
                    }
                case .failure(let error):
                    print(error)
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

}

#Preview {
    HomeTabsView()
}



