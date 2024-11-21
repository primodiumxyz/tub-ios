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
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @StateObject private var tokenManager = CodexTokenManager.shared

    // chevron animation
    @State private var chevronOffset: CGFloat = 0.0
    @State private var isMovingUp: Bool = true

    // swipe animation
    @State private var offset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    @State private var dragging = false
    @State private var isDragStarting = true

    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }

    @ObservedObject var tokenListModel: TokenListModel
    @StateObject private var animationState = TokenAnimationState.shared

    @State private var isLoading = false

    private func canSwipe(value: DragGesture.Value) -> Bool {
        return activeTab != "sell"
            // not trying to swipe up from the first token
            && !(value.translation.height > 0 && tokenListModel.currentTokenIndex == 0)
            // not trying to swipe down when there is only one token available (the current one)
            && !(value.translation.height < 0 && !tokenListModel.isNextTokenAvailable)
    }

    private func loadToken(_ geometry: GeometryProxy, _ direction: String) {
        if direction == "previous" {
            tokenListModel.loadPreviousToken()
            withAnimation {
                activeOffset += geometry.size.height
            }
        }
        else {
            tokenListModel.loadNextToken()
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
                currentTokenModel: tokenListModel.currentTokenModel
            )
            .zIndex(2)

            if tokenListModel.isLoading {
                LoadingTokenView()
            }
            else {
                ZStack(alignment: .top) {
                    // Main content
                    ZStack {
                        (activeTab == "sell"
                            ? AppColors.primaryPinkGradient
                            : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom))
                            .ignoresSafeArea()

                        VStack(spacing: 0) {
                            // Rest of the content
                            if tokenListModel.tokens.count == 0 {
                                Spacer()
                                Text("Failed to load tokens.")
                                    .foregroundColor(AppColors.lightYellow)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 24)
                                Button(action: {
                                    Task {
                                        await tokenManager.refreshToken(hard: true)
                                        tokenListModel.subscribeTokens()
                                    }
                                }) {
                                    Text("Retry")
                                        .font(.sfRounded(size: .lg, weight: .semibold))
                                        .foregroundColor(AppColors.white)
                                        .frame(maxWidth: 300)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(AppColors.primaryPurple)
                                        .cornerRadius(30)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 30)
                                                .inset(by: 0.5)
                                                .stroke(AppColors.primaryPurple, lineWidth: 1)
                                        )
                                }
                                Spacer()
                            }
                            else {
                                GeometryReader { geometry in
                                    VStack(spacing: 10) {
                                        LoadingTokenView()
                                            .frame(height: geometry.size.height)
                                            .opacity(dragging ? 0.8 : 0)
                                        TokenView(
                                            tokenModel: tokenListModel.currentTokenModel,
                                            onSellSuccess: {
                                                withAnimation {
                                                    notificationHandler.show(
                                                        "Successfully sold tokens!",
                                                        type: .success
                                                    )
                                                }
                                            }
                                        )
                                        .frame(height: geometry.size.height - 25)

                                        LoadingTokenView()
                                            .frame(height: geometry.size.height)
                                            .opacity(dragging ? 0.8 : 0)

                                    }
                                    .zIndex(1)
                                    .offset(y: -geometry.size.height - 35 + offset + activeOffset)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if canSwipe(value: value) {
                                                    if isDragStarting {
                                                        isDragStarting = false
                                                        // todo: show the next token
                                                    }

                                                    dragging = true
                                                    offset = value.translation.height
                                                }
                                            }
                                            .onEnded { value in
                                                isDragStarting = true

                                                if canSwipe(value: value) {
                                                    let threshold: CGFloat = 50
                                                    if value.translation.height > threshold {
                                                        loadToken(geometry, "previous")
                                                    }
                                                    else if value.translation.height < -threshold {
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

                    // Bubbles effect
                    if animationState.showSellBubbles {
                        BubbleEffect(isActive: $animationState.showSellBubbles)
                            .zIndex(998)
                    }
                }
                .foregroundColor(.white)
            }
        }.onAppear {
            tokenListModel.subscribeTokens()
        }
        .onDisappear {
            tokenListModel.unsubscribeTokens()
        }
    }
}
