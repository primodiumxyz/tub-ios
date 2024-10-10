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
    
    @State private var chevronOffset: CGFloat = 0.0
    @State private var isMovingUp: Bool = true
    
    init() {
        self._tokenModel = StateObject(wrappedValue: TokenModel(userId: UserDefaults.standard.string(forKey: "userId") ?? ""))
    }

    private func updateTokenModel(tokenId: String) {
        DispatchQueue.main.async {
            tokenModel.initialize(with: tokenId)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Your Net Worth")
                    .font(.sfRounded(size: .sm, weight: .bold))
                    .opacity(0.7)
                    .kerning(-1)
                
                Text("\(userModel.balance + tokenModel.tokenBalance * (tokenModel.prices.last?.price ?? 0), specifier: "%.2f") SOL")
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
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let verticalAmount = value.translation.height
                                if verticalAmount < -50 {
                                    // Swipe up (next token)
                                    withAnimation {
                                        let newIndex = (currentTokenIndex + 1) % tokens.count
                                        currentTokenIndex = newIndex
                                        updateTokenModel(tokenId: tokens[newIndex].id)
                                    }
                                } else if verticalAmount > 50 {
                                    // Swipe down (previous token)
                                    withAnimation {
                                        let newIndex = (currentTokenIndex - 1 + tokens.count) % tokens.count
                                        currentTokenIndex = newIndex
                                        updateTokenModel(tokenId: tokens[newIndex].id)
                                    }
                                }
                            }
                    )
                
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
                            .foregroundColor(.gray)
                            .offset(y: chevronOffset)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center) // Center the button
                .padding(.bottom)
            }
        }
        .onAppear{
            startChevronAnimation()
            fetchTokens()
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.black) 
    }
    
    // Chevron Animation
    private func startChevronAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {
                chevronOffset = isMovingUp ? 12 : -12
            }
            isMovingUp.toggle() 
        }
    }

    private func fetchTokens() {
        subscription = Network.shared.apollo.subscribe(subscription: GetLatestMockTokensSubscription()) { result in
            DispatchQueue.global(qos: .background).async {
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
}

#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    TokenListView()
        .environmentObject(UserModel(userId: userId))
}



