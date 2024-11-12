//
//  TubApp.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import SwiftUI

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
    @State var userId : String = ""
    
    var body: some View {
        Group{
            if userId == "" {
                MockRegisterView(register: {
                    UserManager.shared.register(onRegister: {_ in })
                })
            } else {
                HomeTabsView(userId: userId).font(.sfRounded())
            }
        }.onAppear{

            UserManager.shared.onUserUpdate { userId in
                self.userId = userId
            }
        }
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


struct MockRegisterView : View {
    var register: () -> Void
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12){
                Spacer()
                    .frame(height: geometry.size.height * 0.25)
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal,10)
                
                Text("Welcome to tub")
                    .font(.sfRounded(size: .xl2, weight: .semibold))
                    .foregroundColor(AppColors.white)
                    .padding(.horizontal,10)
                VStack(alignment: .center){
                    Button(action: register) {
                        Text("Register")
                            .font(.sfRounded(size: .lg, weight: .semibold))
                            .padding(18)
                    }
                    .background(AppColors.darkGreenGradient)
                    .foregroundStyle(AppColors.white)
                    .cornerRadius(15)
                    
                }.frame(maxWidth: .infinity).padding(.top)
            }
            .padding(.horizontal)
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.darkBlueGradient)
        
    }
}
