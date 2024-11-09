//
//  HomeTabView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

struct HomeTabsView: View {
    var color = Color(red: 0.43, green: 0.97, blue: 0.98)
    @StateObject private var priceModel : SolPriceModel
    @StateObject private var userModel : UserModel
    @State private var selectedTab: Int = 0 // Track the selected tab
    @State private var isKeyboardVisible = false
    
    init(userId: String) {
        _priceModel = StateObject(wrappedValue: SolPriceModel())
        _userModel = StateObject(wrappedValue: UserModel(userId: userId))
    }
    
    var body: some View {
        Group {
            if userModel.isLoading || !priceModel.isReady {
                LoadingView()
            } else {
                ZStack(alignment: .bottom) {
                    // Main content view
                    Group {
                        if selectedTab == 0 {
                            TokenListView(walletAddress: userModel.walletAddress)
                        } else if selectedTab == 1 {
                            HistoryView()
                        } else if selectedTab == 2 {
                            AccountView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.black)
                    
                    // Custom Tab Bar
                    if !isKeyboardVisible {  // Only show tab bar when keyboard is hidden
                        HStack {
                            Spacer()
                            
                            // Explore Tab
                            Button(action: { selectedTab = 0 }) {
                                VStack {
                                    Image(systemName: "safari")
                                        .font(.system(size: 24))
                                    Text("Explore")
                                        .font(.sfRounded(size: .xs, weight: .regular))
                                }
                                .foregroundColor(selectedTab == 0 ? color : AppColors.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            // History Tab
                            Button(action: { selectedTab = 1 }) {
                                VStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 24))
                                    Text("History")
                                        .font(.sfRounded(size: .xs, weight: .regular))
                                }
                                .foregroundColor(selectedTab == 1 ? color : AppColors.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            // Account Tab
                            Button(action: { selectedTab = 2 }) {
                                VStack {
                                    Image(systemName: "person")
                                        .font(.system(size: 24))
                                    Text("Account")
                                        .font(.sfRounded(size: .xs, weight: .regular))
                                }
                                .foregroundColor(selectedTab == 2 ? color : AppColors.white.opacity(0.5))
                            }
                            
                            Spacer()
                        }
                        .background(AppColors.black)
                        .ignoresSafeArea(.keyboard)
                    }
                }
                .onAppear {
                    setupKeyboardNotifications()
                }
                .onDisappear {
                    removeKeyboardNotifications()
                }
            }
        }
        .environmentObject(userModel)
        .environmentObject(priceModel)
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

#Preview {
    @Previewable @StateObject var errorHandler = ErrorHandler()
    @Previewable @State var userId : String? = nil
    Group {
        if userId == nil {
            LoadingView()
        } else {
            HomeTabsView(userId: userId!)
        }
    }
        .environmentObject(errorHandler)
    .onAppear {
        Task {
            do {
                userId = try await privy.refreshSession().user.id
                print(userId)
            } catch {
                print("error in preview: \(error)")
            }
        }
    }
}
