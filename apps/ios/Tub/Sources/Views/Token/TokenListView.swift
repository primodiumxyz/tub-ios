//
//  TokenListView.swift
//  Tub
//
//  Created by Henry on 10/2/24.
//

import SwiftUI
import TubAPI
import UIKit

enum DraggingState {
    case none
    case canSwipe
    case cannotSwipe
}

struct TokenListView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var notificationHandler: NotificationHandler
    
    var emptyTokenModel = TokenModel()
    // chevron animation
    @State private var chevronOffset: CGFloat = 0.0
    
    // swipe animation
    @State private var dragGestureOffset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    
    @State private var draggingState = DraggingState.none
    
    @State private var animateCurrentTokenModel = true
    @State private var isAutoScrolling = false
    private let offsetThresholdToDragToAnotherToken = 125.0
    private let autoScrollAnimationDuration = 0.35
    private let autoScrollAnimationAbortedDuration = 0.15
    private let autoScrollSpringAnimationBounce = 0.35  // [0,1] where 1 is very springy
    private let moveToDragGestureOffsetAnimationDuration = 0.25
    
    var balanceToken: Int {
        userModel.tokenData[tokenListModel.currentTokenModel.tokenId]?.balanceToken ?? 0
    }
    
    var activeTab: PurchaseState {
        return balanceToken > 0 ? .sell : .buy
    }
    
    @EnvironmentObject var tokenListModel: TokenListModel
    
    @State private var isLoading = false
    
    private enum SwipeDirection {
        case up
        case down
    }
    
    private func canSwipe(direction: SwipeDirection) -> Bool {
        if isAutoScrolling {
            return false
        }
        
        if activeTab == .sell {
            return false
        }
        
        if direction == .up {
            return tokenListModel.canSwipeUp()
        } else if direction == .down {
            return tokenListModel.canSwipeDown()
        }
        
        return true
    }
    
    private func postAutoScrollResets() {
        activeOffset = 0
        dragGestureOffset = 0
        draggingState = .none
        animateCurrentTokenModel = true
        isAutoScrolling = false
    }
    
    private func loadToken(_ geometry: GeometryProxy, _ direction: SwipeDirection) {
        animateCurrentTokenModel = false
        isAutoScrolling = true
        
        if direction == .up {
            // Step #1: Animate to the new TokenView
            //            withAnimation(.spring(duration: autoScrollAnimationDuration, bounce: autoScrollSpringAnimationBounce)) {
            withAnimation(.easeOut(duration: autoScrollAnimationDuration)) {
                activeOffset += (geometry.size.height - dragGestureOffset)
            } completion: {
                // Step #2: While the "main/center" TokenView is still scrolled out of view,
                //	call loadPreviousTokenIntoCurrentTokenPhaseOne() which takes care of
                //	transitioning previousTokenModel to now become currentTokenModel. This hides
                //	the visual glitch that comes when the chart is given a completely
                //	different set of prices to plot: this transition is visually jarring.
                let loadSuccess = tokenListModel.loadPreviousTokenIntoCurrentTokenPhaseOne()
                if loadSuccess {
                    // Step #3: Wait a beat to allow the currentTokenModel chart price rendering
                    //	to settle before resetting dragGestureOffset that results in the
                    //	"main/center" TokenView being centered again. With the offset now reset,
                    //	we setup the new previous token now that its View is safely offscreen.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        postAutoScrollResets()
                        tokenListModel.loadPreviousTokenIntoCurrentTokenPhaseTwo()
                    }
                } else {
                    postAutoScrollResets()
                }
            }
        } else {
            // Step #1: Animate to the new TokenView
            //            withAnimation(.spring(duration: autoScrollAnimationDuration, bounce: autoScrollSpringAnimationBounce)) {
            withAnimation(.easeOut(duration: autoScrollAnimationDuration)) {
                activeOffset -= (geometry.size.height + dragGestureOffset)
            } completion: {
                // Step #2: While the "main/center" TokenView is still scrolled out of view,
                //	call loadNextTokenIntoCurrentTokenPhaseOne() which takes care of
                //	transitioning nextTokenModel to now become currentTokenModel. This hides
                //	the visual glitch that comes when the chart is given a completely
                //	different set of prices to plot: this transition is visually jarring.
                tokenListModel.loadNextTokenIntoCurrentTokenPhaseOne()
                
                // Step #3: Wait a beat to allow the currentTokenModel chart price rendering
                //	to settle before resetting dragGestureOffset that results in the
                //	"main/center" TokenView being centered again. With the offset now reset,
                //	we setup the new next token now that its View is safely offscreen.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    postAutoScrollResets()
                    tokenListModel.loadNextTokenIntoCurrentTokenPhaseTwo()
                }
            }
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack {
                AccountBalanceView(
                    userModel: userModel
                )
                .zIndex(3)
                
                if tokenListModel.totalTokenCount == 0 && !tokenListModel.initialFetchComplete {
                    GeometryReader { geometry in
                        TokenView(
                            tokenModel: TokenModel()
                        )
                        .frame(height: geometry.size.height)
                    }
                } else {
                    // Main content
                    
                    VStack(spacing: 0) {
                        // Rest of the content
                        if tokenListModel.totalTokenCount == 0 && tokenListModel.initialFetchComplete {
                            ErrorView(
                                errorMessage: "No tokens found.", retryAction: tokenListModel.startTokenSubscription
                            )
                            .frame(maxHeight: .infinity)
                        }
                        
                    }
                    
                    if tokenListModel.totalTokenCount > 0 {
                        GeometryReader { geometry in
                            VStack(spacing: 0) {
                                // Previous TokenView that's offscreen above
                                TokenView(
                                    tokenModel: tokenListModel.previousTokenModel ?? emptyTokenModel,
                                    animate: false
                                )
                                .frame(height: geometry.size.height)
                                .opacity(draggingState == DraggingState.canSwipe ? 1 : 0)
                                
                                // Current focused TokenModel that's centered onscreen
                                TokenView(
                                    tokenModel: tokenListModel.currentTokenModel,
                                    animate: animateCurrentTokenModel
                                )
                                .frame(height: geometry.size.height)
                                
                                // Next TokenView that's offscreen below
                                TokenView(
                                    tokenModel: tokenListModel.nextTokenModel ?? emptyTokenModel,
                                    animate: false
                                )
                                .frame(height: geometry.size.height)
                                .opacity(draggingState == .canSwipe ? 1 : 0)
                            }
                            .zIndex(1)
                            .offset(y: -geometry.size.height + dragGestureOffset + activeOffset)
                            .highPriorityGesture(
                                DragGesture()
                                    .onChanged { value in
                                        let dragDirection =
                                        value.translation.height > 0 ? SwipeDirection.up : SwipeDirection.down
                                        if canSwipe(direction: dragDirection) {
                                            draggingState = .canSwipe
                                            dragGestureOffset = value.translation.height
                                        } else {
                                            // Allow a tug effect by limiting the drag offset
                                            draggingState = .cannotSwipe
                                            dragGestureOffset = value.translation.height * 0.2  // Limit the tug effect
                                        }
                                    }
                                    .onEnded { value in
                                        let dragDirection =
                                        value.translation.height > 0 ? SwipeDirection.up : SwipeDirection.down
                                        if canSwipe(direction: dragDirection) {
                                            if value.translation.height > offsetThresholdToDragToAnotherToken {
                                                loadToken(geometry, .up)
                                            } else if value.translation.height < -offsetThresholdToDragToAnotherToken {
                                                loadToken(geometry, .down)
                                            } else {
                                                withAnimation(.easeOut(duration: autoScrollAnimationAbortedDuration)) {
                                                    dragGestureOffset = 0
                                                } completion: {
                                                    draggingState = .none
                                                }
                                            }
                                        } else {
                                            // Reset the tug effect
                                            withAnimation(.easeOut(duration: autoScrollAnimationAbortedDuration)) {
                                                dragGestureOffset = 0
                                            } completion: {
                                                draggingState = .none
                                            }
                                        }
                                    }
                            )
                        }.zIndex(1)
                            .clipped()
                        
                    }
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                // this prevents the screen from being half scrolled after closing the app
                activeOffset = 0
                dragGestureOffset = 0
            }
        }
    }
}
