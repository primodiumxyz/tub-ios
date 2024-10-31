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
    @AppStorage("userId") private var userId = ""
    @State var isPrivySdkReady = false
    
    var body: some Scene {
        WindowGroup {
            Group{
                if !isPrivySdkReady {
                    LoadingView()
                }
                else if userId.isEmpty {
                    AccountSetupView().font(.sfRounded())
                } else {
                    HomeTabsView().font(.sfRounded())
                }
            }.onAppear(perform: {
                privy.setAuthStateChangeCallback { state in
                    if !self.isPrivySdkReady && state != AuthState.notReady {
                        self.isPrivySdkReady = true
                    }
                }
            })
        }
    }
}

#Preview {
    HomeTabsView()
        .font(.sfRounded())
}

#Preview("Account Setup") {
    AccountSetupView()
        .font(.sfRounded())
}
