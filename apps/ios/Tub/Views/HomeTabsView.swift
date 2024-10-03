//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

struct HomeTabsView: View {
    var color = Color(red: 0.43, green: 0.97, blue: 0.98)
    var body: some View {
        
        TabView() {
            RemoteCoinsView().tabItem {
                Label("Cloud", systemImage: "cloud.fill")
            }
            CoinView(_coinModel: LocalCoinModel(tokenId: "")).tabItem {
                Label("Local", systemImage: "testtube.2")
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
