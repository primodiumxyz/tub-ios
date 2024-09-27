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
            ExploreView().tabItem {
                Label("Explore", systemImage: "list.dash")
            }.badge(2)
            CollectionView().tabItem {
                Label("Collection", systemImage: "list.dash")
            }.tag(2)
            MessageView().tabItem {
                Label("Message", systemImage: "list.dash")
            }.tag(3)
        }
    }
}

#Preview {
    HomeTabsView()
}
