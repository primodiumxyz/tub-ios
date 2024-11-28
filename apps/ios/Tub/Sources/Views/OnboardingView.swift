//
// OnboardingView.swift
//  Tub
//
//  Created by yixintan on 11/20/24.
//

import SwiftUI
import WebKit
import AVKit

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var userModel: UserModel
    @State private var currentPage = 0
    @State private var showBubbles = false
    
    let onboardingData = [
        OnboardingPage(
            title: "Swipe Up to Explore",
            subtitle: "Navigate through coins by swiping up.",
            backgroundImage: nil
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
                
                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            VStack(spacing: 16) {
                                Spacer()
                                
                                Text(onboardingData[index].title)
                                    .font(.sfRounded(size: .xl2, weight: .semibold))
                                    .foregroundStyle(Color("aquaGreen"))
                                    .padding(.top, 30)
                                
                                Text(onboardingData[index].subtitle)
                                    .font(.sfRounded(size: .lg, weight: .regular))
                                    .foregroundStyle(Color("magneta"))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                if index == 0 {
                                    VideoPlayerView(videoName: "onboarding1")
                                        .frame(width: 300, height: 500)
                                        
                                } else if index == 1 {
                                    VideoPlayerView(videoName: "onboarding1")
                                        .frame(width: 300, height: 500)
                                        
                                } else if index == 2 {
                                    VideoPlayerView(videoName: "onboarding1")
                                        .frame(width: 300, height: 500)
                                }
                                Spacer()
                                
                            }
                            .tag(index)
                            .onChange(of: currentPage) { oldValue, newValue in
                                if newValue == 1 {
                                    showBubbles = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.8) {
                                        showBubbles = true
                                    }
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    OutlineButton(
                        text: currentPage == onboardingData.count - 1 ? "Get Started" : "Continue",
                        textColor: Color("aquaGreen"),
                        strokeColor: Color("aquaGreen"),
                        backgroundColor: Color.black,
                        maxWidth:.infinity,
                        action: {
                            if currentPage < onboardingData.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                
                if currentPage == 1 {
                    BubbleEffect(isActive: $showBubbles)
                        .opacity(showBubbles ? 1 : 0)
                        .animation(.easeIn, value: showBubbles)
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

struct VideoPlayerView: UIViewRepresentable {
    let videoName: String
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)
        containerView.backgroundColor = .clear
        
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            let player = AVPlayer(url: url)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspect
            containerView.layer.addSublayer(playerLayer)
            
            // Store references
            containerView.tag = 100
            containerView.layer.setValue(playerLayer, forKey: "playerLayer")
            containerView.layer.setValue(player, forKey: "player")
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }
            
            player.play()
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let playerLayer = uiView.layer.value(forKey: "playerLayer") as? AVPlayerLayer {
                playerLayer.frame = uiView.bounds
            }
        }
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        if let player = uiView.layer.value(forKey: "player") as? AVPlayer {
            player.pause()
        }
    }
}


#Preview {
    OnboardingView()
        .environmentObject(UserModel.shared)
} 

