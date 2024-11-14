//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI
import PrivySDK

struct HomeTabsView: View {
    var color = Color(red: 0.43, green: 0.97, blue: 0.98)
    @StateObject private var priceModel : SolPriceModel
    @StateObject private var userModel : UserModel
    @State private var selectedTab: Int = 0 // Track the selected tab
    @State private var tabStartTime: Date? = nil
  
  
    init(userId: String, walletAddress: String, linkedAccounts: [PrivySDK.LinkedAccount]?) {
        _priceModel = StateObject(wrappedValue: SolPriceModel())
        _userModel = StateObject(wrappedValue: UserModel(userId: userId, walletAddress: walletAddress, linkedAccounts: linkedAccounts))
    }

    private func recordTabDwellTime(_ previousTab: String) {
        guard let startTime = tabStartTime else { return }

        let dwellTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)

        Network.shared.recordClientEvent(
            event: ClientEvent(
                eventName: "tab_dwell_time",
                source: "home_tabs_view",
                metadata: [
                    ["tab_name": previousTab],
                    ["dwell_time_ms": dwellTimeMs],
                ]
            )
        ) { result in
            switch result {
            case .success:
                print("Successfully recorded tab dwell time")
            case .failure(let error):
                print("Failed to record tab dwell time: \(error)")
            }
        }


    private func recordTabSelection(_ tabName: String) {
        // Record dwell time for previous tab
        let previousTab: String
        switch selectedTab {
        case 0: previousTab = "explore"
        case 1: previousTab = "history"
        case 2: previousTab = "account"
        default: previousTab = "unknown"
        }

        if tabStartTime != nil {
            recordTabDwellTime(previousTab)
        }

        // Record selection of new tab
        Network.shared.recordClientEvent(
            event: ClientEvent(
                eventName: "tab_selected",
                source: "home_tabs_view",
                metadata: [
                    ["tab_name": tabName]
                ]
            )
        ) { result in
            switch result {
            case .success:
                print("Successfully recorded tab selection")
            case .failure(let error):
                print("Failed to record tab selection: \(error)")
            }
        }

        // Start timing for new tab
        tabStartTime = Date()
    }

    var body: some View {
        Group {
            if userModel.isLoading {
                LoadingView(
                    identifier: "HomeTabsView - waiting for userModel & priceModel",
                    message: "loading player data")
            } else {
                ZStack(alignment: .bottom) {
                    // Main content view
                    Group {
                        if selectedTab == 0 {
                            TokenListView(walletAddress: userModel.walletAddress)
                        } else if selectedTab == 1 {
                            HistoryView()
                        } else if selectedTab == 2 {
                            AccountView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.black)

                    // Custom Tab Bar
                    HStack {
                        Spacer()

                        // Explore Tab
                        Button(action: {
                            selectedTab = 0
                            recordTabSelection("explore")
                        }) {
                            VStack {
                                Image(systemName: "safari")
                                    .font(.system(size: 24))
                                Text("Explore")
                                    .font(.sfRounded(size: .xs, weight: .regular))
                            }
                            .foregroundColor(
                                selectedTab == 0 ? color : AppColors.white.opacity(0.5))
                        }

                        Spacer()

                        // History Tab
                        Button(action: {
                            selectedTab = 1
                            recordTabSelection("history")
                        }) {
                            VStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 24))
                                Text("History")
                                    .font(.sfRounded(size: .xs, weight: .regular))
                            }
                            .foregroundColor(
                                selectedTab == 1 ? color : AppColors.white.opacity(0.5))
                        }

                        Spacer()

                        // Account Tab
                        Button(action: {
                            selectedTab = 2
                            recordTabSelection("account")
                        }) {
                            VStack {
                                Image(systemName: "person")
                                    .font(.system(size: 24))
                                Text("Account")
                                    .font(.sfRounded(size: .xs, weight: .regular))
                            }
                            .foregroundColor(
                                selectedTab == 2 ? color : AppColors.white.opacity(0.5))
                        }

                        Spacer()
                    }
                    .background(AppColors.black)
                    .ignoresSafeArea(.keyboard)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(userModel)
        .environmentObject(priceModel)
    }
}
