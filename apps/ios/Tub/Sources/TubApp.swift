//
//  TubApp.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI
import PrivySDK

@main
struct TubApp: App {
    
    var body: some Scene {
        WindowGroup {
            AppContent()
        }
    }
}

struct AppContent : View {
    @StateObject private var errorHandler = ErrorHandler()
    @State var userId : String = ""
    @State var authState: PrivySDK.AuthState = .unauthenticated
    @State var embeddedWalletState: PrivySDK.EmbeddedWalletState = .notCreated
    @State var embeddedWalletAddress: String = ""
    @State var authError: Error? = nil {
        didSet {
            if let error = authError {
                errorHandler.show(error)
            }
        }
    }
    @State var walletError: Error? = nil
    
    var body: some View {
        ZStack {
            Group {
                if let error = walletError {
                    LoginErrorView(
                        errorMessage: error.localizedDescription,
                        retryAction: {
                            Task {
                                authError = nil
                                walletError = nil
                                // Retry connection
                                do {
                                   let _ = try await privy.refreshSession()
                                } catch {
                                    errorHandler.show(error)
                                }
                            }
                        }
                    )
                } else if userId == "" || authError != nil {
                    RegisterView()
                } else if authState == .notReady || embeddedWalletState.toString == "connecting" {
                    LoadingView(message: "Connecting wallet")
                }
                else if embeddedWalletAddress == "" {
                    CreateWalletView()
                }
                else     {
                    HomeTabsView(userId: userId, walletAddress: embeddedWalletAddress).font(.sfRounded())
                }
            }
            .zIndex(0)
        }
        .withErrorHandling()
        .environmentObject(errorHandler)
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

