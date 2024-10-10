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
    
    //swipe animation
    @State private var dragOffset: CGFloat = 0.0
    @State private var swipeDirection: CGFloat = 0.0 // Track swipe direction
    @State private var animatingSwipe: Bool = false

    
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
                    .offset(y: dragOffset)
                    .gesture(
                        DragGesture()
                        .onChanged { value in
                            // Update offset as the user drags
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 100
                            let verticalAmount = value.translation.height
                            
                            if verticalAmount < -threshold && !animatingSwipe {
                                
                                // Swipe Up (Next token)
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    dragOffset = -UIScreen.main.bounds.height
                                    swipeDirection = -1
                                }
                                animatingSwipe = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    loadNextToken()
                                    resetDragOffset()
                                }
                            } else if verticalAmount > threshold && !animatingSwipe {
                                
                                // Swipe Down (Previous token)
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    dragOffset = UIScreen.main.bounds.height
                                    swipeDirection = 1
                                }
                                animatingSwipe = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    loadPreviousToken()
                                    resetDragOffset()
                                }
                            } else {
                                withAnimation {
                                    dragOffset = 0 // Reset if not enough swipe
                                }
                            }
                        }
                        
                        
                    )
                
                VStack(alignment: .center) {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .offset(y: chevronOffset)
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
    
    private func loadNextToken() {
        let newIndex = (currentTokenIndex + 1) % tokens.count
        currentTokenIndex = newIndex
        updateTokenModel(tokenId: tokens[newIndex].id)
    }

    private func loadPreviousToken() {
        let newIndex = (currentTokenIndex - 1 + tokens.count) % tokens.count
        currentTokenIndex = newIndex
        updateTokenModel(tokenId: tokens[newIndex].id)
    }

    // Reset the drag offset
    private func resetDragOffset() {
        withAnimation(.easeInOut(duration: 0.3)) {
            dragOffset = swipeDirection == -1 ? UIScreen.main.bounds.height : -UIScreen.main.bounds.height
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                dragOffset = 0
                animatingSwipe = false
            }
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



