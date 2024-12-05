//
// OnboardingView.swift
//  Tub
//
//  Created by yixintan on 11/20/24.
//

import AVKit
import SwiftUI
import WebKit

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var userModel: UserModel
    @State private var currentPage = 0
    @State private var showBubbles = false
    @Environment(\.screenSize) private var screenSize
    
    let onboardingData = [
        OnboardingPage(
            title: "Swipe to explore the hottest coins",
            subtitle: "Our AI finds the best coins to buy and sell.",
            mediaTitle: "onboarding1"
        ),
        OnboardingPage(
            title: "Instant profits with one tap",
            subtitle: "Perfect your timing for maximum gains!",
            mediaTitle: "onboarding1"
        ),
    ]
    
    private func completeOnboarding() {
        userModel.hasSeenOnboarding = true
        dismiss()
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            VStack(spacing: geometry.size.height * 0.02) {
                                Spacer()
                                
                                Text(onboardingData[index].title)
                                    .font(.sfRounded(size: .xl2, weight: .semibold))
                                    .foregroundStyle(.tubBuyPrimary)
                                    .padding(.top, geometry.size.height * 0.04)
                                    .multilineTextAlignment(.center)
                                
                                if let subtitle = onboardingData[index].subtitle {
                                    Text(subtitle)
                                        .font(.sfRounded(size: .lg, weight: .regular))
                                        .foregroundStyle(.tubSellPrimary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, geometry.size.width * 0.1)
                                }
                                
                                if let mediaTitle = onboardingData[index].mediaTitle {
                                    let videoHeight = min(geometry.size.height * 0.5, 412)
                                    let videoWidth = min(geometry.size.width * 0.5, 200)
                                    
                                    VideoPlayerView(videoName: mediaTitle)
                                        .padding(.top, geometry.size.height * 0.02)
                                        .padding(.horizontal, 4)
                                        .frame(width: videoWidth, height: videoHeight)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(Color.gray, lineWidth: 2)
                                        )
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
                        textColor: .tubBuyPrimary,
                        strokeColor: .tubBuyPrimary,
                        backgroundColor: .clear,
                        maxWidth: .infinity,
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
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .padding(.bottom, geometry.size.height * 0.05)
                }
                .navigationBarHidden(true)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String?
    let mediaTitle: String?

    init(title: String, subtitle: String? = nil, mediaTitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.mediaTitle = mediaTitle
    }
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
        .preferredColorScheme(.light)
}
