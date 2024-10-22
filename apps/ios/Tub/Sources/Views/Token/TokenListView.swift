//
//  TokenListView.swift
//  Tub
//
//  Created by Henry on 10/2/24.
//

import SwiftUI
import Apollo
import TubAPI
import UIKit

struct TokenListView: View {
    @EnvironmentObject private var userModel: UserModel
    
    @State private var availableTokens: [Token] = []
    @State private var currentToken: Token?

    @State private var isLoading = true
    @State private var subscription: Cancellable?
    @State private var errorMessage: String?
    
    @State private var currentTokenIndex: Int = 0
    @StateObject private var tokenModel: TokenModel
    
    // chevron animation
    @State private var chevronOffset: CGFloat = 0.0
    @State private var isMovingUp: Bool = true
    
    // swipe animation
    @State private var offset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    @State private var dragging = false
    
    // show info card
    @State private var showInfoCard = false
    @State var activeTab: String = "buy"
    
    init() {
        self._tokenModel = StateObject(wrappedValue: TokenModel(userId: UserDefaults.standard.string(forKey: "userId") ?? ""))
    }
    
    private func updateTokenModel(tokenId: String) {
        DispatchQueue.main.async {
            tokenModel.initialize(with: tokenId)
        }
    }
    
    var pinkStops = [
        Gradient.Stop(color: Color(red: 0.77, green: 0.38, blue: 0.6).opacity(0.4), location: 0.00),
        Gradient.Stop(color: .black.opacity(0), location: 0.37),
    ]
    
    var purpleStops = [
        Gradient.Stop(color: Color(red: 0.43, green: 0, blue: 1).opacity(0.4), location: 0.0),
        Gradient.Stop(color: .black, location: 0.37),
    ]
    
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                stops: activeTab == "buy" ? purpleStops : pinkStops,
                startPoint: UnitPoint(x: 0.5, y: activeTab == "buy" ? 1 : 0),
                endPoint: UnitPoint(x: 0.5, y: activeTab == "buy" ? 0 : 1)
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Account balance view
                VStack(alignment: .leading) {
                    Text("Account Balance")
                        .font(.sfRounded(size: .sm, weight: .bold))
                        .opacity(0.7)
                        .kerning(-1)
                    
                    let tokenValue = tokenModel.tokenBalance * (tokenModel.prices.last?.price ?? 0)
                    Text("\(PriceFormatter.formatPrice(userModel.balance + tokenValue)) SOL")
                        .font(.sfRounded(size: .xl3))
                        .fontWeight(.bold)
                    
                    let adjustedChange = userModel.balanceChange + tokenValue
                    HStack {
                        Text(adjustedChange >= 0 ? "+" : "-")
                        Text("\(abs(adjustedChange), specifier: "%.2f") SOL")
                        
                        let adjustedPercentage = (adjustedChange / userModel.initialBalance) * 100
                        Text("(\(abs(adjustedPercentage), specifier: "%.1f")%)")
                        
                        // Format time elapsed
                        Text("\(formatTimeElapsed(userModel.timeElapsed))")
                            .foregroundColor(.gray)
                    }
                    .font(.sfRounded(size: .sm, weight: .semibold))
                    .foregroundColor(adjustedChange >= 0 ? .green : .red)
                }
                .padding()
                .padding(.top, 35)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(dragging ? AppColors.black : nil)
                .ignoresSafeArea()
                .zIndex(2)
                
                // Rest of the content
                if isLoading {
                    LoadingView()
                } else if currentToken == nil {
                    Text("No tokens found").foregroundColor(.red)
                } else {
                    GeometryReader { geometry in
                        VStack(spacing: 10) {
                              // TODO: keep an array of previous tokens so we can swipe up (disable when we reached the first token)
                              TokenView(tokenModel: tokenModel, activeTab: $activeTab)
                                .frame(height: geometry.size.height)
                                .opacity(dragging ? 1 : 0)
                            TokenView(tokenModel: tokenModel, activeTab: $activeTab)
                                .frame(height: geometry.size.height)
                            TokenView(tokenModel: getNextTokenModel(), activeTab: Binding.constant("buy"))
                                .frame(height: geometry.size.height)
                                .opacity(dragging ? 0.2 : 0)
                        }
                        .padding(.horizontal)
                        .zIndex(1)
                        .offset(y: -geometry.size.height - 40 + offset + activeOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if activeTab != "sell" {
                                        dragging = true
                                        offset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    if activeTab != "sell" {
                                        let threshold: CGFloat = -50
                                        if value.translation.height < threshold {
                                            loadNextToken()
                                            withAnimation {
                                                activeOffset -= geometry.size.height
                                            }
                                        }
                                        withAnimation {
                                            offset = 0
                                        }
                                        // Delay setting dragging to false to allow for smooth animation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            dragging = false
                                        }
                                    }
                                }
                        ).zIndex(1)
                    }
                }
                
                if showInfoCard {
                    TokenInfoCardView(tokenModel: tokenModel, isVisible: $showInfoCard)
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .foregroundColor(.white)
        .background(Color.black)
        .onAppear {
            fetchTokens()
        }
    }
    
    private func getRandomToken(excluding currentId: String? = nil) -> Token? {
        guard !availableTokens.isEmpty else { return nil }
        guard availableTokens.count > 1 else { return availableTokens[0] }
        var newToken: Token
        repeat {
            let randomIndex = Int.random(in: 0..<availableTokens.count)
            newToken = availableTokens[randomIndex]
        } while newToken.id == currentId

        return newToken
    }
    
    private func loadNextToken() {
        if let newToken = getRandomToken(excluding: currentToken?.id) {
            currentToken = newToken
            updateTokenModel(tokenId: newToken.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.activeOffset = 0
            }
        }
    }
    
    private func getNextTokenModel() -> TokenModel {
        if let nextToken = getRandomToken(excluding: currentToken?.id) {
            return TokenModel(userId: UserDefaults.standard.string(forKey: "userId") ?? "", tokenId: nextToken.id)
        }
        return tokenModel // Return current model if no new token is available
    }
    
    private func fetchTokens() {
        subscription = Network.shared.apollo.subscribe(subscription: SubFilteredTokensSubscription(
            since: Date().addingTimeInterval(-30).ISO8601Format(),
            minTrades: "10",
            minIncreasePct: "5"
        )) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let error = graphQLResult.errors {
                        self.errorMessage = "Error: \(error)"
                    }
                    if let tokens = graphQLResult.data?.getFormattedTokens {
                        let newTokens = tokens.map { elem in 
                            Token(id: elem.token_id, name: elem.name ?? "", symbol: elem.symbol ?? "", mint: elem.mint, imageUri: nil)
                        }
                        self.availableTokens = newTokens
                        if self.currentToken == nil {
                            self.initRandomToken()
                        }
                    }
                case .failure(let error):
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func initRandomToken() {
        guard !availableTokens.isEmpty else { return }
        let randomIndex = Int.random(in: 0..<availableTokens.count)
        currentToken = availableTokens[randomIndex]
        updateTokenModel(tokenId: currentToken!.id)
    }
    
    private func formatTimeElapsed(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60

        if hours > 1 {
            return "past \(hours) hours"
        } else if hours > 0 {
            return "past hour"
        } else if minutes > 1 {
            return "past \(minutes) minutes"
        } else  {
            return "past minute"
        }
    }
}

#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    TokenListView()
        .environmentObject(UserModel(userId: userId))
}
