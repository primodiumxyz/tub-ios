//
//  AccountSetupView.swift
//  Tub
//
//  Created by Henry on 10/8/24.
//

import SwiftUI

struct AccountSetupView: View {
    @AppStorage("userId") private var userId = ""
    @State private var isRegistered = false
    @State private var username = ""
    
    var body: some View {
        VStack {
            if userId.isEmpty {
                RegisterView(isRegistered: $isRegistered)
            } else {
                Text("Your user id: \(userId)")
                    .multilineTextAlignment(.center) // {{ edit_1 }}
            }
        }
        .onChange(of: isRegistered) { newValue in
            if newValue {
                // Refresh the view to show the welcome message
                userId = UserDefaults.standard.string(forKey: "userId") ?? ""
            }
        }
    }
}

#Preview {
    AccountSetupView()
}
