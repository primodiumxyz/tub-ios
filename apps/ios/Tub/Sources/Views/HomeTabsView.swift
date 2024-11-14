//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

struct HomeTabsView: View {
    var color = Color(red: 0.43, green: 0.97, blue: 0.98)
    @StateObject private var priceModel : SolPriceModel
    @StateObject private var userModel : UserModel
    @State private var selectedTab: Int = 0 // Track the selected tab
    
    init(userId: String, walletAddress: String) {
        _priceModel = StateObject(wrappedValue: SolPriceModel())
        _userModel = StateObject(wrappedValue: UserModel(userId: userId, walletAddress: walletAddress))
    }
    
    var body: some View {
        Group {
            if let error = userModel.error {
                LoginErrorView(
                    errorMessage: error,
                    retryAction: {
                        Task {
                            await userModel.fetchInitialData()
                        }
                    }
                )
            } 
            else if userModel.isLoading  {
                LoadingView(identifier: "HomeTabsView - waiting for userModel & priceModel", message: "Loading user data")
            } else {
                ZStack(alignment: .bottom) {
                    // Main content view
                    Group {
                        if selectedTab == 0 {
                            TokenListView(walletAddress: userModel.walletAddress)
                        } else if selectedTab == 1 {
                            HistoryView()
                        } else if selectedTab == 2 {
                            AccountView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.black)
                    
                    // Custom Tab Bar
                        HStack {
                            Spacer()
                            
                            // Explore Tab
                            Button(action: { selectedTab = 0 }) {
                                VStack {
                                    Image(systemName: "safari")
                                        .font(.system(size: 24))
                                    Text("Explore")
                                        .font(.sfRounded(size: .xs, weight: .regular))
                                }
                                .foregroundColor(selectedTab == 0 ? color : AppColors.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            // History Tab
                            Button(action: { selectedTab = 1 }) {
                                VStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 24))
                                    Text("History")
                                        .font(.sfRounded(size: .xs, weight: .regular))
                                }
                                .foregroundColor(selectedTab == 1 ? color : AppColors.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            // Account Tab
                            Button(action: { selectedTab = 2 }) {
                                VStack {
                                    Image(systemName: "person")
                                        .font(.system(size: 24))
                                    Text("Account")
                                        .font(.sfRounded(size: .xs, weight: .regular))
                                }
                                .foregroundColor(selectedTab == 2 ? color : AppColors.white.opacity(0.5))
                            }
                            
                            Spacer()
                        }
                        .background(AppColors.black)
                        .ignoresSafeArea(.keyboard)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(userModel)
        .environmentObject(priceModel)
    }
}

