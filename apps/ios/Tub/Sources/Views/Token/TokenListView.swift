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
    
    @State private var showNotification = false
    
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
    
    
    var body: some View {
        VStack {
            AccountBalanceView(
                userModel: userModel,
                currentTokenModel: viewModel.currentTokenModel
            )
            .zIndex(2)
               Divider()
                        .frame(width: 300, height: 1)
                        .overlay(
                            Rectangle()
                                .stroke(AppColors.lightGray.opacity(0.3), lineWidth: 0.5)
                        )
            if viewModel.isLoading {
                    DummyTokenView(height: 400)
                        .frame(height: .infinity)
                
            } else {
                ZStack(alignment: .top) {
                    // Main content
                    ZStack {
                        (activeTab == "sell" ?
                         AppColors.primaryPinkGradient :
                            LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom))
                        .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            // Rest of the content
                            if viewModel.tokens.count == 0 {
                                Spacer()
                                Text("Failed to load tokens.")
                                    .foregroundColor(AppColors.lightYellow)
                                    .multilineTextAlignment(.center)
                                Button(action: {
                                    viewModel.fetchTokens(setLoading: true)
                                }) {
                                    Text("Retry")
                                }
                                Spacer()
                            } else {
                                GeometryReader { geometry in
                                    VStack(spacing: 10) {
                                        DummyTokenView(height: geometry.size.height)
                                            .frame(height: geometry.size.height)
                                            .opacity(dragging ? 0.8 : 0)
                                        TokenView(
                                            tokenModel: viewModel.currentTokenModel,
                                            activeTab: $activeTab,
                                            onSellSuccess: {
                                                withAnimation {
                                                    showNotification = true
                                                }
                                            }
                                        )
                                        .frame(height: geometry.size.height - 25)
                                        DummyTokenView(height: geometry.size.height)
                                            .frame(height: geometry.size.height)
                                            .opacity(dragging ? 0.8 : 0)

                                        
                                    }
                                    .zIndex(1)
                                    .offset(y: -geometry.size.height - 35 + offset + activeOffset)
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
                    }
                    
                    // Notification banner
                    if showNotification {
                        NotificationBanner(
                            message: "Successfully sold tokens!",
                            type: .success,
                            isPresented: $showNotification
                        )
                        .zIndex(999) // Ensure it's above everything else
                    }
                    
                    // Bubbles effect
                    if animationState.showSellBubbles {
                        BubbleEffect(isActive: $animationState.showSellBubbles)
                            .zIndex(998)
                    }
                }
                .foregroundColor(.white)
            }
        } .onAppear {
            viewModel.subscribeTokens()
        }
    }
}

