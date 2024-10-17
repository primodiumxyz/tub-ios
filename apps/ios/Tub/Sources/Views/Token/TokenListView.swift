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
    
    @State private var tokens: [Token] = []
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
    
    @State private var previousTokenModel: TokenModel?
    @State private var nextTokenModel: TokenModel?
    
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
                    
                    let totalBalance = userModel.balance.total + tokenModel.tokenBalance.total * (tokenModel.prices.last?.price ?? 0)
                    Text("\(totalBalance, specifier: "%.2f") SOL")
                        .font(.sfRounded(size: .xl3))
                        .fontWeight(.bold)
                    
                    let changeAmount = totalBalance - userModel.lastHourBalance
                    let changePercentage = userModel.lastHourBalance != 0 ? (changeAmount / userModel.lastHourBalance) * 100 : 0
                    HStack {
                        
                        Text(changeAmount >= 0 ? "+" : "-")
                        Text("\(abs(changeAmount), specifier: "%.2f") SOL")
                        Text("(\(changePercentage, specifier: "%.1f")%)")
                        Text("last hour")
                            .foregroundColor(.gray)
                    }
                    .font(.sfRounded(size: .sm, weight: .semibold))
                    .foregroundColor(changeAmount >= 0 ? .green : .red)
                
                // todo: add gains
                }
                .padding()
                .padding(.top, 35)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.black)
                .ignoresSafeArea()
                .zIndex(2)
                
                // Rest of the content
                if isLoading {
                    LoadingView()
                } else if tokens.isEmpty {
                    Text("No tokens found").foregroundColor(.red)
                } else {
                    GeometryReader { geometry in
                        VStack(spacing: 10) {
                            TokenView(tokenModel: previousTokenModel ?? getPreviousTokenModel(), activeTab: $activeTab)
                                .frame(height: geometry.size.height)
                                .opacity(dragging ? 1 : 0)
                            TokenView(tokenModel: tokenModel, activeTab: $activeTab)
                                .frame(height: geometry.size.height)
                            TokenView(tokenModel: nextTokenModel ?? getNextTokenModel(), activeTab: Binding.constant("buy"))
                                .frame(height: geometry.size.height)
                                .opacity(dragging ? 1 : 0.2)
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
                                        let threshold: CGFloat = 50
                                        if value.translation.height > threshold {
                                            loadPreviousToken()
                                            withAnimation {
                                                activeOffset += geometry.size.height
                                            }
                                        } else if value.translation.height < -threshold {
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
            userModel.startBalanceUpdates()
        }
        .onDisappear {
            userModel.stopBalanceUpdates()
        }
    }
    
    private func getPreviousTokenModel() -> TokenModel {
        let previousIndex = (currentTokenIndex - 1 + tokens.count) % tokens.count
        return TokenModel(userId: UserDefaults.standard.string(forKey: "userId") ?? "", tokenId: tokens[previousIndex].id)
    }
    
    private func getNextTokenModel() -> TokenModel {
        let nextIndex = (currentTokenIndex + 1) % tokens.count
        return TokenModel(userId: UserDefaults.standard.string(forKey: "userId") ?? "", tokenId: tokens[nextIndex].id)
    }
    
    private func loadNextToken() {
        currentTokenIndex = (currentTokenIndex + 1) % tokens.count
        previousTokenModel = tokenModel
        updateTokenModel(tokenId: tokens[currentTokenIndex].id)
        nextTokenModel = getNextTokenModel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            activeOffset = 0
        }
    }
    
    private func loadPreviousToken() {
        currentTokenIndex = (currentTokenIndex - 1 + tokens.count) % tokens.count
        nextTokenModel = tokenModel
        updateTokenModel(tokenId: tokens[currentTokenIndex].id)
        previousTokenModel = getPreviousTokenModel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            activeOffset = 0
        }
    }
    
    private func fetchTokens() {
        subscription = Network.shared.apollo.subscribe(subscription: SubLatestMockTokensSubscription()) { result in
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let graphQLResult):
                        if let tokens = graphQLResult.data?.token {
                            self.tokens = tokens.map { elem in Token(id: elem.id, name: elem.name, symbol: elem.symbol) }
                            updateTokenModel(tokenId: tokens[0].id)
                            previousTokenModel = getPreviousTokenModel()
                            nextTokenModel = getNextTokenModel()
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
