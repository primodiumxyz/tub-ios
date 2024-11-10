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
    @State var myAuthState : AuthState = AuthState.notReady
    @State var userId : String = ""
    @State var walletState : EmbeddedWalletState = EmbeddedWalletState.notCreated
    
    var body: some View {
        Group{
            if myAuthState.toString == "error" {
                VStack {
                    Text("Error connecting wallet. Please Try Again.")
                    Button(action: privy.logout) {
                        Text("Logout")
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black).foregroundColor(.white)
            }
            else if myAuthState == .unauthenticated {
                RegisterView()
            } else if walletState == EmbeddedWalletState.notCreated {
                CreateWalletView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black).foregroundColor(.white)
            }
            else if myAuthState.toString != "authenticated" || walletState.toString != "connected" {
                LoadingView()
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

