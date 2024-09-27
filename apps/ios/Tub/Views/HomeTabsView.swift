//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

struct HomeTabsView: View {
    var body: some View {
        TabView(selection: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Selection@*/.constant(1)/*@END_MENU_TOKEN@*/) {
            CoinView().tabItem {
                Label("Explore", systemImage: "house")
            }.badge(2)
            CollectionView().tabItem {
                Label("Collection", systemImage: "heart")
            }
            MessageView().tabItem {
                Label("Message", systemImage: "message")
            }
        }
    }
}

#Preview {
    HomeTabsView()
}
