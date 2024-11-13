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

    var body: some View {
        ZStack {
            VStack {
                Text("Auth state: \(authState.toString)")
                Text("Embedded wallet state: \(embeddedWalletState.toString)")
                Text("userId: \(userId)")
            }
            .backgroundStyle(.black)
            .foregroundStyle(.white)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top)
            .zIndex(1)
            
            Group {
                if userId == "" {
                    RegisterView()
                } else if authState == .notReady || embeddedWalletState.toString == "connecting" {
                    LoadingView(message: "Connecting user account...")
                }
                else if embeddedWalletAddress == "" {
                    CreateWalletView()
                }
                else     {
                    HomeTabsView(userId: userId).font(.sfRounded())
                }
            }
            .zIndex(0)
        }.onAppear{
            privy.setAuthStateChangeCallback { state in
                // Logic to execute after there is an auth change.
                self.authState = state
                switch state {
                case .authenticated(let authSession):
                    self.userId = authSession.user.id
                default:
                    self.userId = ""
                }
            }
            privy.embeddedWallet.setEmbeddedWalletStateChangeCallback { state in
                // Logic to execute after there is an auth change.
                self.embeddedWalletState = state
                switch state {
                case .connected(let wallets):
                    print("Embedded wallets : \(wallets.map { $0.address })")
                    if let solanaWallet = wallets.first(where: { $0.chainType == .solana }) {
                        self.embeddedWalletAddress = solanaWallet.address
                    }
                default:
                    break
                }
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
