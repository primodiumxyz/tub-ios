//
//  CoinListView.swift
//  Tub
//
//  Created by Henry on 10/2/24.
//

import SwiftUI
import Apollo
import TubAPI

struct CoinListView: View {
    @EnvironmentObject private var userModel: UserModel
    
    @State private var coins: [Coin] = []
    @State private var isLoading = true
    @State private var subscription: Cancellable?
    @State private var errorMessage: String?
    
    @State private var currentCoinIndex: Int = 0
    @StateObject private var coinModel: RemoteCoinModel
    
    init() {
        self._coinModel = StateObject(wrappedValue: RemoteCoinModel(userId: UserDefaults.standard.string(forKey: "userId") ?? ""))
    }
    
    private func updateCoinModel(tokenId: String) {
        print("updating coin model", tokenId)
        coinModel.initialize(with: tokenId)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Your Net Worth")
                    .font(.sfRounded(size: .sm, weight: .bold))
                    .opacity(0.7)
                    .kerning(-1)
                
                Text("\(userModel.balance, specifier: "%.2f") SOL")
                    .font(.sfRounded(size: .xl4))
                    .fontWeight(.bold)
            }
            
            if isLoading || coinModel.loading {
                VStack {
                    LoadingView()
                }
            } else if coins.isEmpty {
                Text("No coins found").foregroundColor(.red)
            } else {
                CoinView(coinModel: coinModel) // Pass as Binding
                    .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
                    .transition(.move(edge: .top))
                Spacer()
                
                VStack(alignment: .center) {
                    Button(action: {
                        withAnimation {
                            let newIndex = (currentCoinIndex + 1) % coins.count
                            print("newIndex: \(newIndex)")
                            currentCoinIndex = newIndex
                            updateCoinModel(tokenId: coins[newIndex].id)
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center) // Center the button
                .padding(.bottom)
            }
        }
        .onAppear(perform: fetchCoins)
        .foregroundColor(.white)
        .padding()
        .background(Color.black) // Corrected syntax
    }

    private func fetchCoins() {
        subscription = Network.shared.apollo.subscribe(subscription: GetLatestMockTokensSubscription()) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let tokens = graphQLResult.data?.token {
                        self.coins = tokens.map { elem in Coin(id: elem.id, name: elem.name, symbol: elem.symbol) }
                        updateCoinModel(tokenId: tokens[0].id)
                    }
                case .failure(let error):
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    CoinListView()
        .environmentObject(UserModel(userId: userId))
}



