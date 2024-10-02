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
    @State private var coinIds: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if let error = errorMessage {
                Text(error).foregroundColor(.black)
            } else if coinIds.isEmpty {
                Text("No coins found").foregroundColor(.red)
            } else {
                List(coinIds, id: \.self) { coinId in
                    Text(coinId)
                }
            }
        }
        .onAppear(perform: fetchCoinIds)
    }

    private func fetchCoinIds() {
        Network.shared.apollo.fetch(query: GetAllTokensQuery()) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let tokens = graphQLResult.data?.token {
                        self.coinIds = tokens.map { $0.id }
                    } else {
                        self.errorMessage = "No tokens data received"
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



