//
// OnboardingView.swift
//  Tub
//
//  Created by yixintan on 11/20/24.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var userModel: UserModel
    @State private var currentPage = 0
    @State private var showBubbles = false
    
    let onboardingData = [
        OnboardingPage(
            title: "Swipe Up to Explore",
            subtitle: "Navigate through coins by swiping up.",
            backgroundImage: "Logo"
        ),
        OnboardingPage(
            title: "1-Click Trading",
            subtitle: "Take profits with one click when the market pumps!",
            backgroundImage: nil
        ),
        OnboardingPage(
            title: "Good Luck!",
            subtitle: "Jump in and start trading now!",
            backgroundImage: nil
        )
    ]
    
    private func completeOnboarding() {
        userModel.hasSeenOnboarding = true
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if currentPage == 1 {
                    BubbleEffect(isActive: $showBubbles)
                        .opacity(showBubbles ? 1 : 0)
                        .animation(.easeIn, value: showBubbles)
                }
                
                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            VStack(spacing: 8) {
                                Text(onboardingData[index].title)
                                    .font(.sfRounded(size: .xl2, weight: .semibold))
                                    .foregroundStyle(AppColors.aquaGreen)
                                
                                Text(onboardingData[index].subtitle)
                                    .font(.sfRounded(size: .lg, weight: .regular))
                                    .foregroundStyle(AppColors.magenta)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                if let bgImage = onboardingData[index].backgroundImage {
                                    Image(bgImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                                }
                            }
                            .tag(index)
                            .onChange(of: currentPage) { oldValue, newValue in
                                if newValue == 1 {
                                    showBubbles = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        showBubbles = true
                                    }
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    Spacer()
                    
                    Button {
                        if currentPage < onboardingData.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage == onboardingData.count - 1 ? "Get Started" : "Continue")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .cornerRadius(30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .inset(by: 0.5)
                                    .stroke(AppColors.aquaGreen, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let backgroundImage: String?
}

#Preview {
    OnboardingView()
        .environmentObject(UserModel.shared)
} 
