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
    
    var body: some View {
        Group{
            if myAuthState.toString == "notReady" || userId == "" || walletState == .connecting {
                LoadingView()
            }
            else if myAuthState.toString != "authenticated" {
                RegisterView()
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
                if myAuthState.toString == "authorized" { return }
                
                self.myAuthState = state
                Task {
                    do {
                        userId = try await privy.refreshSession().user.id
                    } catch {
                        print("error fetching session", error)
                    }
                }
            }
        })
    }
}

#Preview {
    AppContent()
}

