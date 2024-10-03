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
            CollectionView().tabItem {
                Label("Collection", systemImage: "list.dash")
            }
            MessageView().tabItem {
                Label("Message", systemImage: "list.dash")
            }
            CoinView().tabItem {
                Label("Explore", systemImage: "house")
            }
        }
    }
}

#Preview {
    HomeTabsView()
}
