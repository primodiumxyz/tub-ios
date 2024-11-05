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
    
    init(userId: String) {
        _priceModel = StateObject(wrappedValue: SolPriceModel())
        _userModel = StateObject(wrappedValue: UserModel(userId: userId))
    }
    
    var body: some View {
        Group {
            if userModel.isLoading || !priceModel.isReady {
                LoadingView()
            } else {
                TabView(selection: $selectedTab) { // Bind the selected tab
                    TokenListView()
                        .tabItem {
                            Label("Explore", systemImage: "safari")
                        }
                        .tag(0)
                    
                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock")
                        }
                        .tag(1)
                    
                    AccountView().tabItem {
                        Label("Account", systemImage: "person")
                    }
                    .tag(2)
                }
                .background(AppColors.black)
                .foregroundColor(AppColors.white)
                .accentColor(color)
                .onAppear {
                    UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.5)
                    
                }
            }
        }
        .environmentObject(userModel)
        .environmentObject(priceModel)
    }
}

#Preview {
    @Previewable @State var userId : String? = nil
    Group {
        if userId == nil {
            LoadingView()
        } else {
            HomeTabsView(userId: userId!)
        }
    }.onAppear {
        Task {
            do {
                userId = try await privy.refreshSession().user.id
                print(userId)
            } catch {
                print("error in preview: \(error)")
            }
        }
    }
}
