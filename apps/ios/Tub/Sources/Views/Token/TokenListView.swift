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
    @State private var nextToken: Token?

    @State private var isLoading = true
    @State private var subscription: Cancellable?
    @State private var errorMessage: String?
    
    @StateObject private var currentTokenModel: TokenModel
    @StateObject private var nextTokenModel: TokenModel
    
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
        self._currentTokenModel = StateObject(wrappedValue: TokenModel(userId: UserDefaults.standard.string(forKey: "userId") ?? ""))
        self._nextTokenModel = StateObject(wrappedValue: TokenModel(userId: UserDefaults.standard.string(forKey: "userId") ?? ""))
    }
    
    private func updateTokenModel(tokenId: String, isCurrentToken: Bool) {
        DispatchQueue.main.async {
            if isCurrentToken {
                currentTokenModel.initialize(with: tokenId)
            } else {
                nextTokenModel.initialize(with: tokenId)
            }
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
        currentToken = nextToken
        updateTokenModel(tokenId: nextToken?.id ?? "", isCurrentToken: true)
        
        if let newNextToken = getRandomToken(excluding: currentToken?.id) {
            nextToken = newNextToken
            updateTokenModel(tokenId: newNextToken.id, isCurrentToken: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.activeOffset = 0
        }
    }
    
    private func initializeTokens() {
        guard !availableTokens.isEmpty else { return }
        
        if currentToken == nil {
            currentToken = getRandomToken()
            updateTokenModel(tokenId: currentToken?.id ?? "", isCurrentToken: true)
        }
        
        if nextToken == nil {
            nextToken = getRandomToken(excluding: currentToken?.id)
            updateTokenModel(tokenId: nextToken?.id ?? "", isCurrentToken: false)
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
                    
                    let tokenValue = currentTokenModel.tokenBalance * (currentTokenModel.prices.last?.price ?? 0)
                    Text("\(PriceFormatter.formatPrice(userModel.balance + tokenValue)) SOL")
                        .font(.sfRounded(size: .xl3))
                        .fontWeight(.bold)
                    
                    let adjustedChange = userModel.balanceChange + tokenValue
                    HStack {
                        Text(adjustedChange >= 0 ? "+" : "-")
                        Text("\(abs(adjustedChange), specifier: "%.2f") SOL")
                        
                        let adjustedPercentage = userModel.initialBalance > 0 ? (adjustedChange / userModel.initialBalance) * 100 : 100;
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
                              TokenView(tokenModel: currentTokenModel, activeTab: $activeTab)
                                .frame(height: geometry.size.height)
                                .opacity(dragging ? 1 : 0)
                            TokenView(tokenModel: currentTokenModel, activeTab: $activeTab)
                                .frame(height: geometry.size.height)
                            TokenView(tokenModel: nextTokenModel, activeTab: Binding.constant("buy"))
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
                    TokenInfoCardView(tokenModel: currentTokenModel, isVisible: $showInfoCard)
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
                    if let tokens = graphQLResult.data?.get_formatted_tokens_since {
                        self.availableTokens = tokens.map { elem in
                            Token(id: elem.token_id, name: elem.name, symbol: elem.symbol, mint: elem.mint, decimals: elem.decimals, imageUri: nil)
                        }
                        
                        self.initializeTokens()
                    }
                case .failure(let error):
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
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
