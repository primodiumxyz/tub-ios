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
    @State private var navigateToHome = false // New state variable for navigation

    
    var body: some View {
        VStack {
            if isRegistered && !userId.isEmpty {
                HomeTabsView()
            }else if userId.isEmpty {
                RegisterView(isRegistered: $isRegistered)
            } else {
                VStack {
                    Text("Your user id: \(userId)")
                        .multilineTextAlignment(.center) // {{ edit_1 }}
                    
                    Button(action: {
                        navigateToHome = true // Set flag to trigger navigation
                    }) {
                        Text("Go to Home")
                            .font(.sfRounded(size: .base, weight: .semibold))
                            .foregroundColor(AppColors.white)
                            .padding()
                            .background(AppColors.primaryPurple)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToHome) {
            HomeTabsView()
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
