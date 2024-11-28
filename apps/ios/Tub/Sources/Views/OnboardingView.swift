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
        ),
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
                                    GIFView(gifName: "swipe")
                                        .frame(width: 300, height: 500)

                                }
                                else if index == 1 {
                                    GIFView(gifName: "buysell")
                                        .frame(width: 300, height: 550)
                                }
                                else if index == 2 {
                                    GIFView(gifName: "history")
                                        .frame(width: 300, height: 550)
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
}
