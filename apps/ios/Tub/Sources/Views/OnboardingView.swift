//
// OnboardingView.swift
//  Tub
//
//  Created by yixintan on 11/20/24.
//

import AVKit
import SwiftUI
import WebKit

/**
 * This view is responsible for displaying the onboarding screen on the first launch of the app.
*/
struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var userModel: UserModel
    @State private var currentPage = 0

    let onboardingData = [
        OnboardingPage(
            title: "Swipe to explore the hottest coins",
            subtitle: "Our AI finds the best coins to buy and sell.",
            mediaTitle: "Onboarding1"
        ),
        OnboardingPage(
            title: "Instant profits with one tap",
            subtitle: "Perfect your timing for maximum gains!",
            mediaTitle: "Onboarding2"
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
                            }

                            if let mediaTitle = onboardingData[index].mediaTitle {
                                ZStack{
                                    Color(UIColor.systemBackground)
                                        .backgroundBubbleEffect()
                                        .zIndex(-1)
                                    
                                    VideoPlayerView(videoName: mediaTitle)
                                        .frame(
                                            width: min(UIScreen.width(Layout.Size.full) * 0.8, 250),
                                            height: min(UIScreen.height(Layout.Size.full) * 0.6, 860)
                                        )
                                        
                                        .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
                                }
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
	
	class Coordinator: NSObject {
		var notificationObserver: NSObjectProtocol?
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)
        containerView.backgroundColor = .clear
        containerView.layer.cornerRadius = 45
        containerView.clipsToBounds = true

        if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            let player = AVPlayer(url: url)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            containerView.layer.addSublayer(playerLayer)

            // Store references
            containerView.tag = 100
            containerView.layer.setValue(playerLayer, forKey: "playerLayer")
            containerView.layer.setValue(player, forKey: "player")

			context.coordinator.notificationObserver = NotificationCenter.default.addObserver(
				forName: AVPlayerItem.didPlayToEndTimeNotification,
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

	static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        if let player = uiView.layer.value(forKey: "player") as? AVPlayer {
            player.pause()
        }
		
		if let notificationObserver = coordinator.notificationObserver as Any? {
			NotificationCenter.default.removeObserver(notificationObserver)
		}
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserModel.shared)
        .preferredColorScheme(.light)
}
