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
        .onChange(of: scenePhase) { phase in
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
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var userModel = UserModel.shared
    @StateObject private var priceModel = SolPriceModel.shared
    
    var body: some View {
        HomeTabsView().font(.sfRounded())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .withErrorHandling()
            .environmentObject(errorHandler)
            .environmentObject(userModel)
            .environmentObject(priceModel)
    }
}

#Preview {
    AppContent()
}

extension View {
    func withErrorHandling() -> some View {
        modifier(ErrorOverlay())
    }
}
