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
    @State var isPrivySdkReady = false
    @State var myAuthState : AuthState = AuthState.notReady
    @State var userId : String = ""
    @State var walletState : EmbeddedWalletState = EmbeddedWalletState.notCreated
    
    var body: some View {
        Group{
            if myAuthState == .unauthenticated {
                RegisterView()
            } else if walletState == EmbeddedWalletState.notCreated {
                CreateWalletView()
            } 
            else if myAuthState.toString != "authenticated" || walletState.toString != "connected" {
                LoadingView(identifier: "TubApp - waiting for authentication")
            }
            else {
                HomeTabsView(userId: userId).font(.sfRounded())
            }
        }.onAppear(perform: {
            privy.embeddedWallet.setEmbeddedWalletStateChangeCallback({
                state in walletState = state
            })
            
            privy.setAuthStateChangeCallback { state in
                self.myAuthState = state
                switch state {
                    case .authenticated(let session):
                        userId = session.user.id
                case .unauthenticated :
                    userId = ""
                default:
                   break
                }
            }
        })
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

