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
    @State var isPrivySdkReady = false
    @State var myAuthState : AuthState = AuthState.notReady
    @State var userId : String = ""
    
    var body: some Scene {
        WindowGroup {
            Group{
                if myAuthState.toString == "notReady" || userId == "" {
                    LoadingView()
                }
                else if myAuthState.toString != "authorized" {
                    RegisterView()
                } else {
                    HomeTabsView(userId: userId).font(.sfRounded())
                }
            }.onAppear(perform: {
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
}

#Preview {
    @Previewable @State var userId : String? = nil
    @Previewable @State var errored: Bool = false
    
    Group {
        if errored {
            Text("You need to register with Privy!")
        } else if userId == nil {
            LoadingView()
        } else {
            HomeTabsView(userId: userId!)
                .font(.sfRounded())
        }
    } .onAppear {
        Task {
            do {
                userId = try await privy.refreshSession().user.id
                print(userId)
            } catch {
                print("error in preview: \(error)")
                errored = true
            }
        }
    }
}

#Preview("Register") {
    RegisterView()
        .font(.sfRounded())
}
