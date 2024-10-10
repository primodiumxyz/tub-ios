//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

struct HomeTabsView: View {
    var color = Color(red: 0.43, green: 0.97, blue: 0.98)
    @AppStorage("userId") private var userId: String = ""

    var body: some View {
        
        TabView() {
            RemoteCoinsView().tabItem {
                Label("Cloud", systemImage: "cloud.fill")
            }
            CoinView(userId: "", tokenId: "", local: true).tabItem {
                Label("Local", systemImage: "testtube.2")
            }
            HistoryView(userId: userId).tabItem {
                Label("History", systemImage: "clock")
            }
        }
        .background(.black)
        .foregroundColor(.white)
        .accentColor(color) // Set the accent color for selected items
        .onAppear {
            UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.5)
        }
    }
}

#Preview {
    HomeTabsView()
}
