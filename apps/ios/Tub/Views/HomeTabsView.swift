//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

struct HomeTabsView: View {
    var body: some View {
            CoinView().tabItem {
                Label("Explore", systemImage: "house")
            }.badge(2)
    }
}

#Preview {
    HomeTabsView()
}
