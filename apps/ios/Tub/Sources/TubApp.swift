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
    @State var authError: Error? = nil
    @State var walletError: Error? = nil
    
    var body: some View {
        Group {
            if let error = authError ?? walletError {
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
            } else if userId == "" {
                RegisterView()
            } else if authState == .notReady || embeddedWalletState.toString == "connecting" {
                LoadingView(message: "Connecting user account...")
            }
            else if embeddedWalletAddress == "" {
                CreateWalletView()
            }
            else     {
                HomeTabsView(userId: userId, walletAddress: embeddedWalletAddress).font(.sfRounded())
            }
        }
        .zIndex(0)
        .onAppear{
            privy.setAuthStateChangeCallback { state in
                switch state {
                case .error(let error):
                    self.authError = error
                case .authenticated(let authSession):
                    self.authError = nil
                    self.userId = authSession.user.id
                default:
                    self.authError = nil
                    self.userId = ""
                }
                self.authState = state
            }
            
            privy.embeddedWallet.setEmbeddedWalletStateChangeCallback { state in
                switch state {
                case .error:
                    self.walletError = NSError(domain: "com.tubapp.wallet", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to connect wallet."])
                case .connected(let wallets):
                    self.walletError = nil
                    if let solanaWallet = wallets.first(where: { $0.chainType == .solana }) {
                        self.embeddedWalletAddress = solanaWallet.address
                    }
                default:
                    break
                }
                self.embeddedWalletState = state
            }
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

