//
// OnboardingView.swift
//  Tub
//
//  Created by yixintan on 11/20/24.
//

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

                                GIFView(gifName: mediaTitle)
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

struct GIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isUserInteractionEnabled = false

        if let url = Bundle.main.url(forResource: gifName, withExtension: "gif") {
            let data = try? Data(contentsOf: url)
            webView.load(
                data!,
                mimeType: "image/gif",
                characterEncodingName: "",
                baseURL: url.deletingLastPathComponent()
            )
        }
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#Preview {
    OnboardingView()
        .environmentObject(UserModel.shared)
        .preferredColorScheme(.light)
}
