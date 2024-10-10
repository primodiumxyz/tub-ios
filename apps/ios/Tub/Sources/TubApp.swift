//
//  TubApp.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

@main
struct TubApp: App {
    @AppStorage("userId") private var userId = ""
    
    var body: some Scene {
        WindowGroup {
            if userId.isEmpty {
                AccountSetupView().font(.sfRounded())
            } else {
                HomeTabsView().font(.sfRounded())
            }
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
