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
    
    // show info card
    @State private var showInfoCard = false
    @State var activeTab: String = "buy"
    
    init() {
        self._viewModel = StateObject(wrappedValue: TokenListModel(userModel: UserModel(userId: UserDefaults.standard.string(forKey: "userId") ?? "")))
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
                AccountBalanceView(
                    userModel: userModel,
                    currentTokenModel: viewModel.currentTokenModel
                )
                .padding(.top, 35)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(dragging ? AppColors.black : nil)
                .ignoresSafeArea()
                .zIndex(2)
                
                // Rest of the content
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.availableTokens.count == 0 {
                    Text("No tokens found").foregroundColor(.red)
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
                
                if showInfoCard {
                    TokenInfoCardView(tokenModel: viewModel.currentTokenModel, isVisible: $showInfoCard)
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .foregroundColor(.white)
        .background(Color.black)
        .onAppear {
            viewModel.fetchTokens()
        }
    }
}

#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    TokenListView()
        .environmentObject(UserModel(userId: userId))
}
