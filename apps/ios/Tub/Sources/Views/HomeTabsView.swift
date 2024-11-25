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
    var color = Color("accentColor")
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    @StateObject private var vm = TabsViewModel()

    @StateObject private var tokenListModel: TokenListModel
    init(userModel: UserModel) {
        self._tokenListModel = StateObject(wrappedValue: TokenListModel(userModel: userModel))
    }

    // Add this to watch for userModel changes
    private var userId: String? {
        didSet {
            if userModel.userId != nil {
                vm.selectedTab = 0  // Force switch to trade tab
                vm.recordTabSelection("trade")
            }
        }
    }

    var body: some View {
        Group {
            if !priceModel.isReady {
                LoadingView(
                    identifier: "HomeTabsView - waiting for userModel & priceModel",
                    message: "Connecting to Solana"
                )
            }
            else {
                
                TabView(selection: $vm.selectedTab) {
                    // Trade Tab
                    
                    TokenListView(tokenListModel: tokenListModel)
                        .tabItem {
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 24))
                                Text("Trade")
                                    .font(.system(size: 12))
                            }
                        }
                        .tag(0)
                        .onAppear {
                            vm.recordTabSelection("trade")
                        }
                    
                    HistoryView()
                        .tabItem {
                            VStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 24))
                                Text("History")
                                    .font(.system(size: 12))
                            }
                        }
                        .tag(1)
                        .onAppear {
                            vm.recordTabSelection("history")
                        }
                    
                    AccountView()
                        .tabItem {
                            VStack {
                                Image(systemName: "person")
                                    .font(.system(size: 24))
                                Text("Account")
                                    .font(.system(size: 12))
                            }
                        }
                        .tag(2)
                        .onAppear {
                            vm.recordTabSelection("account")
                        }
                }
                .background(Color(UIColor.systemBackground))
                .ignoresSafeArea(.keyboard)
                .edgesIgnoringSafeArea(.all)
                
            }
        }
        .onChange(of: userModel.userId) { _, newUserId in
            if newUserId != nil {
                vm.selectedTab = 0  // Force switch to trade tab
                vm.recordTabSelection("trade")
            }
        }
    }
}
