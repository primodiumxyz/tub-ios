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
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        VStack(spacing: UIScreen.height(Layout.Spacing.xs)) {
                            Spacer()

                            Text(onboardingData[index].title)
                                .font(.sfRounded(size: .xl2, weight: .semibold))
                                .foregroundStyle(.tubBuyPrimary)
                                .padding(.top, UIScreen.height(Layout.Spacing.sm))
                                .multilineTextAlignment(.center)

                            if let subtitle = onboardingData[index].subtitle {
                                Text(subtitle)
                                    .font(.sfRounded(size: .lg, weight: .regular))
                                    .foregroundStyle(.tubSellPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, UIScreen.width(Layout.Spacing.md))
                                    .padding(.bottom, UIScreen.height(Layout.Spacing.xs))
                            }

                            if let mediaTitle = onboardingData[index].mediaTitle {
                                VideoPlayerView(videoName: mediaTitle)
                                    .frame(
                                        width: min(UIScreen.width(Layout.Size.half), 300),
                                        height: min(UIScreen.height(Layout.Size.half), 400)
                                    )
                                    .padding(.top, UIScreen.height(Layout.Spacing.xs))
                                    .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Layout.Fixed.cornerRadius)
                                            .stroke(Color.gray, lineWidth: Layout.Fixed.borderWidth)
                                    )
                            }
                            Spacer()
                        }
                        .tag(index)
                        .onChange(of: currentPage) { oldValue, newValue in
                            if newValue == 1 {
                                BubbleManager.shared.trigger() 
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
                .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
                .padding(.bottom, UIScreen.height(Layout.Spacing.md))
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
