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
    @StateObject private var vm = TabsViewModel()  // Make it optional

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
                    identifier: "HomeTabsView - waiting priceModel",
                    message: "Connecting to Solana"
                )
            }
            else {
                ZStack(alignment: .bottom) {
                    // Main content view
                    Group {
                        if vm.selectedTab == 0 {
                            TokenListView()
                        }
                        else if vm.selectedTab == 1 {
                            HistoryView()
                        }
                        else if vm.selectedTab == 2 {
                            AccountView()
                        }
                    }
                    .background(Color.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    HStack {
                        Spacer()

                        // Trade Tab
                        Button(action: {
                            vm.selectedTab = 0
                            vm.recordTabSelection("trade")
                        }) {
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 24))
                                Text("Trade")
                                    .font(.sfRounded(size: .xs, weight: .regular))
                            }
                            .foregroundStyle(
                                vm.selectedTab == 0 ? color : Color.white.opacity(0.5)
                            )
                        }

                        Spacer()

                        // History Tab
                        Button(action: {
                            vm.selectedTab = 1
                            vm.recordTabSelection("history")
                        }) {
                            VStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 24))
                                Text("History")
                                    .font(.sfRounded(size: .xs, weight: .regular))
                            }
                            .foregroundStyle(
                                vm.selectedTab == 1 ? color : Color.white.opacity(0.5)
                            )
                        }

                        Spacer()

                        // Account Tab
                        Button(action: {
                            vm.selectedTab = 2
                            vm.recordTabSelection("account")
                        }) {
                            VStack {
                                Image(systemName: "person")
                                    .font(.system(size: 24))
                                Text("Account")
                                    .font(.sfRounded(size: .xs, weight: .regular))
                            }
                            .foregroundStyle(
                                vm.selectedTab == 2 ? color : Color.white.opacity(0.5)
                            )
                        }

                        Spacer()
                    }
                    .padding(.top, 8)
                    .background(Color.black)
                    .ignoresSafeArea(.keyboard)
                }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.keyboard)
            .onChange(of: userModel.userId) { _, newUserId in
                if newUserId != nil {
                    vm.selectedTab = 0  // Force switch to trade tab
                    vm.recordTabSelection("trade")
                }
            }
    }
}
