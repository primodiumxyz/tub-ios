//
//  TokenListView.swift
//  Tub
//
//  Created by Henry on 10/2/24.
//

import SwiftUI
import TubAPI
import UIKit

struct TokenListView: View {
    @StateObject private var viewModel: TokenListModel
    @EnvironmentObject private var userModel: UserModel
    
    // chevron animation
    @State private var chevronOffset: CGFloat = 0.0
    @State private var isMovingUp: Bool = true
    
    // swipe animation
    @State private var offset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    @State private var dragging = false
    
    @State var activeTab: String = "buy"
    
    @StateObject private var animationState = TokenAnimationState.shared
    
    private func canSwipe(value: DragGesture.Value) -> Bool {
        return activeTab != "sell" &&
            // not trying to swipe up from the first token
            !(value.translation.height > 0 && viewModel.currentTokenIndex == 0) &&
            // not trying to swipe down when there is only one token available (the current one)
            !(value.translation.height < 0 && !viewModel.isNextTokenAvailable)
    }
    
    init(walletAddress: String) {
        self._viewModel = StateObject(wrappedValue: TokenListModel(walletAddress: walletAddress))
    }
    
    private func loadToken(_ geometry: GeometryProxy, _ direction: String) {
        if direction == "previous" {
            viewModel.loadPreviousToken()
            withAnimation {
                activeOffset += geometry.size.height
            }
        } else {
            viewModel.loadNextToken()
            withAnimation {
                activeOffset -= geometry.size.height
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            activeOffset = 0
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
        Group {
            if viewModel.isLoading {
                LoadingView(identifier: "TokenListView - loading")
            } else {
                ZStack {
                    (activeTab == "sell" ? 
                        AppColors.primaryPinkGradient :
                        LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom))
                        .ignoresSafeArea()

                    
                    VStack(spacing: 0) {
                        AccountBalanceView(
                            userModel: userModel,
                            currentTokenModel: viewModel.currentTokenModel
                        )
                        .padding(.horizontal, 10)
                        .background(dragging ? AppColors.black : nil)
                        .zIndex(2)
                        
                        // Rest of the content
                        if viewModel.tokens.count == 0 {
                            Spacer()
                            Text("An unexpected error occurred. Please come back later.")
                                .foregroundColor(AppColors.lightYellow)
                                .multilineTextAlignment(.center)
                            Spacer()
                        } else {
                            GeometryReader { geometry in
                                VStack(spacing: 10) {
                                    TokenView(tokenModel: viewModel.previousTokenModel ?? viewModel.createTokenModel(), activeTab: $activeTab)
                                        .frame(height: geometry.size.height)
                                        .opacity(dragging ? 0.2 : 0)
                                    TokenView(tokenModel: viewModel.currentTokenModel, activeTab: $activeTab)
                                        .frame(height: geometry.size.height)
                                    TokenView(tokenModel: viewModel.nextTokenModel ?? viewModel.createTokenModel(), activeTab: Binding.constant("buy"))
                                        .frame(height: geometry.size.height)
                                        .opacity(dragging ? 0.2 : 0)
                                }
                                .zIndex(1)
                                .offset(y: -geometry.size.height - 40 + offset + activeOffset)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if canSwipe(value: value) {
                                                dragging = true
                                                offset = value.translation.height
                                            }
                                        }
                                        .onEnded { value in
                                            if canSwipe(value: value) {
                                                let threshold: CGFloat = 50
                                                if value.translation.height > threshold {
                                                    loadToken(geometry, "previous")
                                                } else if value.translation.height < -threshold {
                                                    loadToken(geometry, "next")
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
                    }
                    
                    if animationState.showSellBubbles {
                        BubbleEffect(isActive: $animationState.showSellBubbles)
                            .zIndex(999)
                    }
                }
                .foregroundColor(.white)
                .background(Color.black)
                
            }
        } .onAppear {
                viewModel.subscribeTokens()
        }
    }
}

