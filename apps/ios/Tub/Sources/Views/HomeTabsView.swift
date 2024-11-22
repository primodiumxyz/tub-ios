//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import PrivySDK
import SwiftUI

struct HomeTabsView: View {
    var color = Color(red: 0.43, green: 0.97, blue: 0.98)
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel

    @State private var selectedTab: Int = 0  // Track the selected tab
    @State private var tabStartTime: Date? = nil

    @StateObject private var tokenListModel: TokenListModel
    init(userModel: UserModel) {
        self._tokenListModel = StateObject(wrappedValue: TokenListModel(userModel: userModel))
    }

    // Add this to watch for userModel changes
    private var userId: String? {
        didSet {
            if userModel.userId != nil {
                selectedTab = 0  // Force switch to trade tab
                recordTabSelection("trade")
            }
        }
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
    }

    private func recordTabSelection(_ tabName: String) {
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
            if !priceModel.isReady {
                LoadingView(
                    identifier: "HomeTabsView - waiting for userModel & priceModel",
                    message: "Connecting to Solana"
                )
            }
            else {
                ZStack(alignment: .bottom) {
                    // Main content view
                    Group {
                        if selectedTab == 0 {
                            TokenListView(tokenListModel: tokenListModel)
                        }
                        else if selectedTab == 1 {
                            HistoryView()
                        }
                        else if selectedTab == 2 {
                            AccountView()
                        }
                    }
                    .background(AppColors.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Custom Tab Bar
                    VStack {
                        Divider()
                            .frame(width: 340.0, height: 1.0)
                            .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.2))
                            .padding(0)
                        HStack {
                            Spacer()

                            // Trade Tab
                            Button(action: {
                                selectedTab = 0
                                recordTabSelection("trade")
                            }) {
                                VStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 24))
                                    Text("Trade")
                                        .font(.sfRounded(size: .xs, weight: .regular))
                                }
                                .foregroundColor(
                                    selectedTab == 0 ? color : AppColors.white.opacity(0.5)
                                )
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
                                    selectedTab == 1 ? color : AppColors.white.opacity(0.7)
                                )
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
                                    selectedTab == 2 ? color : AppColors.white.opacity(0.7)
                                )
                            }

                            Spacer()
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0),
                                    Color.black.opacity(1),
                                ]),
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: 0.7)
                            )
                        )
                        .ignoresSafeArea(.keyboard)
                    }
                }
                .padding(.top, 8)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.keyboard)
            .onChange(of: userModel.userId) { _, newUserId in
                if newUserId != nil {
                    selectedTab = 0  // Force switch to trade tab
                    recordTabSelection("trade")
                }
            }
    }
}
