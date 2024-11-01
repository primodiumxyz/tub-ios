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
        
        #if DEBUG
        Text("userId: \(userId)")
        Text("walletState: \(walletState.toString)")
        Text("myAuthState: \(myAuthState.toString)")
        #endif
        Group{
            if myAuthState.toString == "notReady" || walletState == .connecting {
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

