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

    private let SCROLL_DURATION = 0.3
    // swipe animation
    @State private var offset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    @State private var dragging = false
    @State private var isDragStarting = true

    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }

    @StateObject var tokenListModel = TokenListModel.shared
    @StateObject private var animationState = TokenAnimationState.shared

    @State private var isLoading = false

    private enum SwipeDirection {
        case up
        case down
    }

    private func canSwipe(direction: SwipeDirection) -> Bool {
        if activeTab == "sell" { return false }
        if direction == .up {
            return tokenListModel.currentTokenIndex != 0
        }
        return true
    }

    private func loadToken(_ geometry: GeometryProxy, _ direction: SwipeDirection) {
        if direction == .up {
            withAnimation {
                activeOffset += geometry.size.height
            }
        }
        else {
            withAnimation {
                activeOffset -= geometry.size.height
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + SCROLL_DURATION) {
            // this adds a one frame delay apparently
            DispatchQueue.main.async {
                if direction == .up {
                    tokenListModel.loadPreviousToken()
                }
                else {
                    tokenListModel.loadNextToken()
                }

                activeOffset = 0
                dragging = false
            }
        }
    }

    var body: some View {
        VStack {
            AccountBalanceView(
                userModel: userModel,
                currentTokenModel: tokenListModel.currentTokenModel
            )
            .zIndex(2)

            if !tokenListModel.isReady {
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
                            if tokenListModel.totalTokenCount == 0 {
                                TokenLoadErrorView()
                            }
                            else {
                                GeometryReader { geometry in
                                    VStack(spacing: 10) {
                                        // PREVIOUS TOKEN
                                        if let previousTokenModel = tokenListModel.previousTokenModel, dragging {
                                            TokenView(tokenModel: previousTokenModel, animate: Binding.constant(false))
                                                .frame(height: geometry.size.height)
                                        }
                                        else {
                                            LoadingTokenView()
                                                .frame(height: geometry.size.height)
                                                .opacity(dragging ? 0.8 : 0)
                                        }

                                        // CURRENT TOKEN
                                        TokenView(
                                            tokenModel: tokenListModel.currentTokenModel,
                                            animate: Binding.constant(true),
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

                                        // NEXT TOKEN
                                        if let nextToken = tokenListModel.nextTokenModel, dragging {
                                            TokenView(tokenModel: nextToken, animate: Binding.constant(false))
                                                .frame(height: geometry.size.height)
                                        }
                                        else {
                                            LoadingTokenView()
                                                .frame(height: geometry.size.height)
                                                .opacity(dragging ? 0.8 : 0)
                                        }

                                    }
                                    .zIndex(1)
                                    .offset(y: -geometry.size.height - 35 + offset + activeOffset)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let direction =
                                                    value.translation.height > 0
                                                    ? SwipeDirection.up : SwipeDirection.down
                                                if !canSwipe(direction: direction) { return }
                                                if isDragStarting {
                                                    isDragStarting = false
                                                    // todo: show the next token
                                                }

                                                dragging = true
                                                offset = value.translation.height
                                            }
                                            .onEnded { value in
                                                isDragStarting = true

                                                let direction =
                                                    value.translation.height > 0
                                                    ? SwipeDirection.up : SwipeDirection.down
                                                if canSwipe(direction: direction) {
                                                    let threshold: CGFloat = 50
                                                    if value.translation.height > threshold {
                                                        loadToken(geometry, .up)
                                                    }
                                                    else if value.translation.height < -threshold {
                                                        loadToken(geometry, .down)
                                                    }
                                                    withAnimation {
                                                        offset = 0
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
            Task {
                await tokenListModel.startTokenSubscription()
            }
        }
        .onDisappear {
            tokenListModel.stopTokenSubscription()
        }
    }
}
struct TokenLoadErrorView: View {
    @StateObject var tokenManager = CodexTokenManager.shared
    @StateObject var tokenListModel = TokenListModel.shared

    var body: some View {
        VStack {
            Spacer()
            Text("Failed to load tokens.")
                .foregroundColor(AppColors.lightYellow)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
            Button(action: {
                Task {
                    await tokenManager.refreshToken(hard: true)
                    await tokenListModel.startTokenSubscription()
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
    }
}
