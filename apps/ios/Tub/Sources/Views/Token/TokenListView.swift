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
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @StateObject private var tokenManager = CodexTokenManager.shared

    var emptyTokenModel = TokenModel()
    // chevron animation
    @State private var chevronOffset: CGFloat = 0.0

    private let SCROLL_DURATION = 0.3
    // swipe animation
    @State private var offset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    @State private var dragging = false
    @State private var isDragStarting = true

    let OFFSET: Double = 5

    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }

    @EnvironmentObject var tokenListModel: TokenListModel
    @State private var showBubbles = false

    @State private var isLoading = false

    private enum SwipeDirection {
        case up
        case down
    }

    private var background: LinearGradient {
        if !tokenListModel.isReady || tokenListModel.totalTokenCount == 0 {
            return LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
        }
        return activeTab == "sell"
            ? Gradients.primaryPinkGradient
            : Gradients.primaryPurpleGradient
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

        ZStack(alignment: .top) {
            // Removes background after redesign

            // background
            //     .animation(.easeInOut(duration: 0.3), value: activeTab)

            if showBubbles {
                BubbleEffect(isActive: $showBubbles)
                    .zIndex(10)
            }
            AccountBalanceView(
                userModel: userModel,
                currentTokenModel: tokenListModel.currentTokenModel
            )
            .zIndex(3)

            if !tokenListModel.isReady {

                GeometryReader { geometry in
                    TokenView(
                        tokenModel: TokenModel(),
                        animate: Binding.constant(false),
                        showBubbles: Binding.constant(false)
                    )
                    .frame(height: geometry.size.height)
                    .offset(y: OFFSET)
                }
            }
            else {
                // Main content

                VStack(spacing: 0) {
                    // Rest of the content
                    if tokenListModel.totalTokenCount == 0 {
                        TokenLoadErrorView()
                    }

                }

                if tokenListModel.totalTokenCount > 0 {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            TokenView(
                                tokenModel: tokenListModel.previousTokenModel ?? emptyTokenModel,
                                animate: Binding.constant(false),
                                showBubbles: Binding.constant(false)
                            )
                            .frame(height: geometry.size.height)
                            .opacity(dragging ? 1 : 0)

                            TokenView(
                                tokenModel: tokenListModel.currentTokenModel,
                                animate: Binding.constant(true),
                                showBubbles: $showBubbles,
                                onSellSuccess: {
                                    withAnimation {
                                        notificationHandler.show(
                                            "Successfully sold tokens!",
                                            type: .success
                                        )
                                    }
                                }
                            )
                            .frame(height: geometry.size.height)
                            TokenView(
                                tokenModel: tokenListModel.nextTokenModel ?? emptyTokenModel,
                                animate: Binding.constant(false),
                                showBubbles: Binding.constant(false)
                            )
                            .frame(height: geometry.size.height)
                            .opacity(dragging ? 1 : 0)
                        }
                        .zIndex(1)
                        .offset(y: -geometry.size.height + OFFSET + offset + activeOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let dragDirection =
                                        value.translation.height > 0 ? SwipeDirection.up : SwipeDirection.down
                                    if canSwipe(direction: dragDirection) {
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

                                    let dragDirection =
                                        value.translation.height > 0 ? SwipeDirection.up : SwipeDirection.down
                                    if canSwipe(direction: dragDirection) {
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
                                        // Delay setting dragging to false to allow for smooth animation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            dragging = false
                                        }
                                    }
                                }
                        )
                    }.zIndex(1)
                }
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
    @EnvironmentObject var tokenListModel: TokenListModel

    var body: some View {
        VStack {
            Spacer()
            Text("Failed to load tokens.")
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
                    .frame(maxWidth: 300)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .inset(by: 0.5)
                            .stroke(Color.purple, lineWidth: 1)
                    )
            }
            Spacer()
        }
    }
}
