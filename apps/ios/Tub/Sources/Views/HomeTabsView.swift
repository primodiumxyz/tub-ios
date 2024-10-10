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

    init() {
        _userModel = StateObject(wrappedValue: UserModel(userId: UserDefaults.standard.string(forKey: "userId") ?? ""))
    }

    var body: some View {
        Group {
            if userModel.isLoading {
                LoadingView()
            } else {
                TabView() {
                    TokenListView().tabItem {
                        Label("Explore", systemImage: "safari")
                    }

                    HistoryView().tabItem {
                        Label("History", systemImage: "clock")
                    }
                    
                    AccountView().tabItem {
                        Label("Account", systemImage: "person")
                    }
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
