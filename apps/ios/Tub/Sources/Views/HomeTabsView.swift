//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import PrivySDK
import SwiftUI

class TabsViewModel: ObservableObject {
    var tabStartTime: Date? = nil
    @Published var selectedTab: Int = 0  // Track the selected tab

    public func recordTabDwellTime(_ previousTab: String) {
        guard let startTime = tabStartTime else { return }

        let dwellTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)

        Task(priority: .low) {
            do {
                try await Network.shared.recordClientEvent(
                    event: ClientEvent(
                        eventName: "tab_dwell_time",
                        source: "home_tabs_view",
                        metadata: [
                            ["tab_name": previousTab],
                            ["dwell_time_ms": dwellTimeMs],
                        ]
                    )
                )
            }
            catch {
                print("Failed to record tab dwell time: \(error)")
            }
        }
    }

    func recordTabSelection(_ tabName: String) {
        // Record dwell time for previous tab
        let previousTab: String
        switch selectedTab {
        case 0: previousTab = "trade"
        case 1: previousTab = "history"
        case 2: previousTab = "account"
        default: previousTab = "unknown"
        }

        if tabStartTime != nil {
            recordTabDwellTime(previousTab)
        }

        // Record selection of new tab
        Task {
            do {
                try await Network.shared.recordClientEvent(
                    event: ClientEvent(
                        eventName: "tab_selected",
                        source: "home_tabs_view",
                        metadata: [
                            ["tab_name": tabName]
                        ]
                    )
                )
                print("Successfully recorded tab selection")
                // Start timing for new tab
            }
            catch {
                print("Failed to record tab selection: \(error)")
            }
            tabStartTime = Date()

        }
    }
}

struct HomeTabsView: View {
    var color = Color(red: 0.43, green: 0.97, blue: 0.98)
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    @StateObject private var vm = TabsViewModel()
    @State private var refreshCounter = 0  // Tracks re-taps on the same tab

    var body: some View {
        Group {
            if !priceModel.isReady {
                LoadingView(
                    identifier: "HomeTabsView - waiting priceModel",
                    message: "Connecting to Solana"
                )
            }
            else {
                VStack {
                    TabView(selection: $vm.selectedTab) {
                        // Trade Tab
                        TokenListView()
                            .id(refreshCounter)
                            .tag(0)

                        NavigationStack {
                            HistoryView()
                                .id(refreshCounter)
                        }
                        .tag(1)
                        
                        NavigationStack {
                            AccountView()
                                .id(refreshCounter)
                        }
                        .tag(2)
                    }
                    .background(Color(UIColor.systemBackground))
                    .ignoresSafeArea(.keyboard)
                    .edgesIgnoringSafeArea(.all)
                    .onChange(of: vm.selectedTab) { oldTab, newTab in
                        let tabName: String
                        switch newTab {
                        case 0: tabName = "trade"
                        case 1: tabName = "history"
                        case 2: tabName = "account"
                        default: tabName = "unknown"
                        }
                        vm.recordTabSelection(tabName)
                        
                        if oldTab == newTab {
                            refreshCounter += 1
                        }
                    }

                    HStack {
                        Spacer()
                        Button {
                            if vm.selectedTab == 0 {
                                refreshCounter += 1
                            }
                            vm.selectedTab = 0
                        } label: {
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 24))
                                Text("Trade")
                                    .font(.system(size: 12))
                            }
                        }
                        Spacer()
                        Button {
                            if vm.selectedTab == 1 {
                                refreshCounter += 1
                            }
                            vm.selectedTab = 1
                        } label: {
                            VStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 24))
                                Text("History")
                                    .font(.system(size: 12))
                            }
                        }
                        Spacer()
                        Button {
                            if vm.selectedTab == 2 {
                                refreshCounter += 1
                            }
                            vm.selectedTab = 2
                        } label: {
                            VStack {
                                Image(systemName: "person")
                                    .font(.system(size: 24))
                                Text("Account")
                                    .font(.system(size: 12))
                            }
                        }
                        Spacer()
                    }
                    .background(Color(UIColor.systemBackground))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
        .onChange(of: userModel.userId) { _, newUserId in
            if newUserId != nil {
                vm.selectedTab = 0  // Force switch to trade tab
                vm.recordTabSelection("trade")
            }
        }
    }
}
