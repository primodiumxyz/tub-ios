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

    let onboardingData = [
        OnboardingPage(
            title: "Swipe to explore the hottest coins",
            subtitle: "Our AI finds the best coins to buy and sell.",
            mediaTitle: "swipe"
        ),
        OnboardingPage(
            title: "Instant profits with one tap",
            subtitle: "Perfect your timing for maximum gains!",
            mediaTitle: "buysell"
        ),
    ]

    private func completeOnboarding() {
        userModel.hasSeenOnboarding = true
        dismiss()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        VStack(spacing: 16) {
                            Spacer()

                            Text(onboardingData[index].title)
                                .font(.sfRounded(size: .xl2, weight: .semibold))
                                .foregroundStyle(.tubBuyPrimary)
                                .padding(.top, 30)

                            if let subtitle = onboardingData[index].subtitle {
                                Text(subtitle)
                                    .font(.sfRounded(size: .lg, weight: .regular))
                                    .foregroundStyle(.tubSellPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }

                            if let mediaTitle = onboardingData[index].mediaTitle {

                                VideoPlayerView(videoName: mediaTitle)
                                    .padding(.top, 16)
                                    .padding(.horizontal, 4)
                                    .frame(width: 200, height: 412.2)
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
                        }
                        else {
                            completeOnboarding()
                        }
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
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
