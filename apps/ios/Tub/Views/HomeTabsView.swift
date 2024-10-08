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
                Label("Explore", systemImage: "house")
            }

            CoinView(coinModel: LocalCoinModel()).tabItem {
                Label("Test", systemImage: "house")
            }

            HistoryView(txs: dummyData).tabItem {
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
