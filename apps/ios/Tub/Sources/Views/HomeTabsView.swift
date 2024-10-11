//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

struct HomeTabsView: View {
    var color = Color(red: 0.43, green: 0.97, blue: 0.98)
    @StateObject private var userModel: UserModel
    @AppStorage("userId") private var userId: String = ""
    @State private var selectedTab: Int = 0 // Track the selected tab

    init() {
        _userModel = StateObject(wrappedValue: UserModel(userId: UserDefaults.standard.string(forKey: "userId") ?? ""))
    }

    var body: some View {
        Group {
            if userModel.isLoading {
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
                .background(.black)
                .foregroundColor(.white)
                .accentColor(color)
                .onAppear {
                    UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.5)
                }
            }
        }
        .environmentObject(userModel)
    }
}

#Preview {
    HomeTabsView()
}
