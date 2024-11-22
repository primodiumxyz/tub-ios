//
//  TubApp.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import PrivySDK
import SwiftUI

@main
struct TubApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let dwellTimeTracker = AppDwellTimeTracker.shared

    var body: some Scene {
        WindowGroup {
            AppContent()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                dwellTimeTracker.startTracking()
            case .background, .inactive:
                dwellTimeTracker.endTracking()
            @unknown default:
                break
            }
        }
    }
}

struct AppContent: View {
    @StateObject private var notificationHandler = NotificationHandler()
    @StateObject private var userModel = UserModel.shared
    @StateObject private var priceModel = SolPriceModel.shared
    @StateObject private var tokenManager = CodexTokenManager.shared

    var body: some View {
        Group {
            if tokenManager.fetchFailed {
                LoginErrorView(
                    errorMessage: "Failed to connect. Please try again.",
                    retryAction: {
                        Task {
                            await tokenManager.refreshToken()
                        }
                    }
                )
            }
            else if !tokenManager.isReady {
                LoadingView(identifier: "Fetching Codex token", message: "Fetching auth token")

            }
            else {
                HomeTabsView(userModel: userModel).font(.sfRounded())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)
                    .withNotificationBanner()
                    .environmentObject(notificationHandler)
                    .environmentObject(userModel)
                    .environmentObject(priceModel)
            }
        }.onAppear {
            Task(priority: .high) {
                await tokenManager.refreshToken()
            }
        }.onChange(of: userModel.walletState) { _, newState in
            if newState == .error {
                notificationHandler.show("Error connecting to wallet.", type: .error)
            }
        }
    }
}

#Preview {
    AppContent()
}

extension View {
    func withNotificationBanner() -> some View {
        modifier(NotificationBanner())
    }
}
