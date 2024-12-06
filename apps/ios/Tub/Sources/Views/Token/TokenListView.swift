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

    // swipe animation
    @State private var dragGestureOffset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    @State private var dragging = false
    @State private var isDragStarting = true
    @State private var animateCurrentTokenModel = true
    private let offsetThresholdToDragToAnotherToken = 125.0
    private let scrollAnimationDuration = 0.3
    private let scrollSpringAnimationBounce = 0.35  // [0,1] where 1 is very springy
    private let moveToDragGestureOffsetAnimationDuration = 0.25

    let OFFSET: Double = 5

    var activeTab: PurchaseState {
        let balance: Int = userModel.balanceToken ?? 0
        return balance > 0 ? .sell : .buy
    }

    @EnvironmentObject var tokenListModel: TokenListModel
    @State private var showBubbles = false

    @State private var isLoading = false

    private enum SwipeDirection {
        case up
        case down
    }

    private func canSwipe(direction: SwipeDirection) -> Bool {
        if activeTab == .sell { return false }
        if direction == .up {
            return tokenListModel.currentTokenIndex != 0
        }
        return true
    }

    private func loadToken(_ geometry: GeometryProxy, _ direction: SwipeDirection) {
        animateCurrentTokenModel = false

        if direction == .up {
            // Step #1: Animate to the new TokenView
            withAnimation(.spring(duration: scrollAnimationDuration, bounce: scrollSpringAnimationBounce)) {
                //alt anim option: withAnimation(.easeOut(duration: scrollAnimationDuration)) {
                activeOffset += (geometry.size.height - dragGestureOffset)
            } completion: {
                // Step #2: While the "main/center" TokenView is still scrolled out of view,
                //	call loadPreviousToken() which takes care of transitioning
                //	previousTokenModel to now become currentTokenModel. This hides
                //	the visual glitch that comes when the chart is given a completely
                //	different set of prices to plot: this transition is visually jarring.
                tokenListModel.loadPreviousToken()

                // Step #3: Wait a beat to let the currentTokenModel chart price rendering
                //	to settle before resetting dragGestureOffset that results in the
                //	"main/center" TokenView being centered again.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    activeOffset = 0
                    dragGestureOffset = 0
                    dragging = false
                    animateCurrentTokenModel = true
                }
            }
        }
        else {
            // Step #1: Animate to the new TokenView
            withAnimation(.spring(duration: scrollAnimationDuration, bounce: scrollSpringAnimationBounce)) {
                //alt anim option: withAnimation(.easeOut(duration: scrollAnimationDuration)) {
                activeOffset -= (geometry.size.height + dragGestureOffset)
            } completion: {
                // Step #2: While the "main/center" TokenView is still scrolled out of view,
                //	call loadPreviousToken() which takes care of transitioning
                //	nextTokenModel to now become currentTokenModel. This hides
                //	the visual glitch that comes when the chart is given a completely
                //	different set of prices to plot: this transition is visually jarring.
                tokenListModel.loadNextToken()

                // Step #3: Wait a beat to let the currentTokenModel chart price rendering
                //	to settle before resetting dragGestureOffset that results in the
                //	"main/center" TokenView being centered again.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    activeOffset = 0
                    dragGestureOffset = 0
                    dragging = false
                    animateCurrentTokenModel = true
                }
            }
        }
    }

    var body: some View {

        ZStack(alignment: .top) {
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
                        tokenModel: TokenModel()
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
                            // Previous TokenView that's offscreen above
                            TokenView(
                                tokenModel: tokenListModel.previousTokenModel ?? emptyTokenModel
                            )
                            .frame(height: geometry.size.height)
                            .opacity(dragging ? 1 : 0)

                            // Current focused TokenModel that's centered onscreen
                            TokenView(
                                tokenModel: tokenListModel.currentTokenModel,
                                animate: animateCurrentTokenModel,
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

                            // Next TokenView that's offscreen below
                            TokenView(
                                tokenModel: tokenListModel.nextTokenModel ?? emptyTokenModel
                            )
                            .frame(height: geometry.size.height)
                            .opacity(dragging ? 1 : 0)
                        }
                        //						.overlay {
                        //							Text("drag offset = \(dragGestureOffset)")
                        //								.font(.title)
                        //								.bold()
                        //						}
                        .zIndex(1)
                        .offset(y: -geometry.size.height + OFFSET + dragGestureOffset + activeOffset)
                        .highPriorityGesture(
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

                                        withAnimation(.easeOut(duration: moveToDragGestureOffsetAnimationDuration)) {
                                            dragGestureOffset = value.translation.height
                                        }
                                    }
                                }
                                .onEnded { value in
                                    isDragStarting = true

                                    let dragDirection =
                                        value.translation.height > 0 ? SwipeDirection.up : SwipeDirection.down
                                    if canSwipe(direction: dragDirection) {
                                        if value.translation.height > offsetThresholdToDragToAnotherToken {
                                            loadToken(geometry, .up)
                                        }
                                        else if value.translation.height < -offsetThresholdToDragToAnotherToken {
                                            loadToken(geometry, .down)
                                        }
                                        else {
                                            withAnimation(
                                                .spring(
                                                    duration: scrollAnimationDuration,
                                                    bounce: scrollSpringAnimationBounce
                                                )
                                            ) {
                                                dragGestureOffset = 0
                                            } completion: {
                                                dragging = false
                                            }
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
