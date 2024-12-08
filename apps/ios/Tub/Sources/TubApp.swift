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
    @StateObject private var userModel = UserModel.shared

    var body: some Scene {
        WindowGroup {
            AppContent()
                .environmentObject(userModel)
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
    @StateObject private var tokenListModel = TokenListModel.shared

    var body: some View {
        Group {
            if let _ = priceModel.error {
                LoginErrorView(
                    errorMessage: "Failed to get price data",
                    retryAction: {
                        Task {
                            await priceModel.fetchPrice()
                        }
                    }
                )
            }
            else {
                HomeTabsView().font(.sfRounded())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .withNotificationBanner()
                    .environmentObject(notificationHandler)
                    .environmentObject(userModel)
                    .environmentObject(tokenListModel)
                    .environmentObject(priceModel)
                    .fullScreenCover(
                        isPresented: .init(
                            get: { !userModel.hasSeenOnboarding },
                            set: { newValue in userModel.hasSeenOnboarding = !newValue }
                        )
                    ) {
                        OnboardingView()
                            .interactiveDismissDisabled()
                    }
            }
        }.onAppear {
            Task(priority: .high) {
                tokenListModel.configure(with: userModel)
                await tokenListModel.startTokenSubscription()
            }
        }.onChange(of: userModel.walletState) { _, newState in
            if newState == .error {
                notificationHandler.show("Error connecting to wallet.", type: .error)
            }
        }
    }
}

#Preview("Light") {
    AppContent().preferredColorScheme(.light)
        .environmentObject(UserModel.shared)
}

#Preview("Dark") {
    AppContent().preferredColorScheme(.dark)
        .environmentObject(UserModel.shared)
}

extension View {
    func withNotificationBanner() -> some View {
        modifier(NotificationBanner())
    }

    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        }
        else {
            self
        }
    }
}
