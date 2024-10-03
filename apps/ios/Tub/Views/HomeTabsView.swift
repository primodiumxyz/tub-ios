//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

struct HomeTabsView: View {
    var body: some View {
        
        TabView() {
            CoinView().tabItem {
                Label("Explore", systemImage: "house")
            }
            HistoryView().tabItem {
                Label("History", systemImage: "clock")
            }
            MessageView().tabItem {
                Label("Notifications", systemImage: "bell.fill")
            }
            
        }
        .padding(0.0)
    }
}

#Preview {
    HomeTabsView()
}
