//
//  TokenListView.swift
//  Tub
//
//  Created by Henry on 10/2/24.
//

import SwiftUI
import Apollo
import TubAPI

struct TokenListView: View {
    @EnvironmentObject private var userModel: UserModel
    
    @State private var tokens: [Token] = []
    @State private var isLoading = true
    @State private var subscription: Cancellable?
    @State private var errorMessage: String?
    
    @State private var currentTokenIndex: Int = 0
    @StateObject private var tokenModel: TokenModel
    
    init() {
        self._tokenModel = StateObject(wrappedValue: TokenModel(userId: UserDefaults.standard.string(forKey: "userId") ?? ""))
    }
    
    private func updateTokenModel(tokenId: String) {
        tokenModel.initialize(with: tokenId)
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
            
            if isLoading || tokenModel.loading {
                VStack {
                    LoadingView()
                }
            } else if tokens.isEmpty {
                Text("No tokens found").foregroundColor(.red)
            } else {
                TokenView(tokenModel: tokenModel) // Pass as Binding
                    .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
                    .transition(.move(edge: .top))
                Spacer()
                
                VStack(alignment: .center) {
                    Button(action: {
                        withAnimation {
                            let newIndex = (currentTokenIndex + 1) % tokens.count
                            currentTokenIndex = newIndex
                            updateTokenModel(tokenId: tokens[newIndex].id)
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
        .onAppear(perform: fetchTokens)
        .foregroundColor(.white)
        .padding()
        .background(Color.black) // Corrected syntax
    }

    private func fetchTokens() {
        subscription = Network.shared.apollo.subscribe(subscription: GetLatestMockTokensSubscription()) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let tokens = graphQLResult.data?.token {
                        self.tokens = tokens.map { elem in Token(id: elem.id, name: elem.name, symbol: elem.symbol) }
                        updateTokenModel(tokenId: tokens[0].id)
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
    TokenListView()
        .environmentObject(UserModel(userId: userId))
}



