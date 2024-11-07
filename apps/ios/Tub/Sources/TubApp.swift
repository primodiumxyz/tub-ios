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
    var body : some Scene {
        WindowGroup {
            AppContent()
        }
    }
    
}

struct AppContent : View {
    @State var isPrivySdkReady = false
    @State var myAuthState : AuthState = AuthState.notReady
    @State var userId : String = ""
    @State var walletState : EmbeddedWalletState = EmbeddedWalletState.notCreated
    
    private var isRegistered: Binding<Bool> {
        Binding(
            get: { self.myAuthState.toString == "authenticated" },
            set: { _ in }  // No-op setter since we handle auth state changes elsewhere
        )
    }
    
    var body: some View {
        Group{
            if myAuthState.toString == "notReady" || walletState == .connecting {
                LoadingView()
            }
            else if myAuthState.toString != "authenticated" {
                RegisterView(isRegistered: isRegistered)
            } else if walletState == EmbeddedWalletState.notCreated {
                CreateWalletView()
            } else {
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
    }
}

#Preview {
    AppContent()
}

