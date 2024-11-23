import PrivySDK
//
//  ActionButtonsView.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//
import SwiftUI

struct ActionButtonsView: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var tokenModel: TokenModel
    @Binding var showBuySheet: Bool
    @StateObject private var animationState = TokenAnimationState.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var isLoginPresented = false
    var handleBuy: (Double) async -> Void
    var onSellSuccess: (() -> Void)?

    init(
        tokenModel: TokenModel,
        showBuySheet: Binding<Bool>,
        handleBuy: @escaping (Double) async -> Void,
        onSellSuccess: (() -> Void)? = nil
    ) {
        self.tokenModel = tokenModel
        self._showBuySheet = showBuySheet
        self.handleBuy = handleBuy
        self.onSellSuccess = onSellSuccess
    }

    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }

    func handleSell() async {
        // Only trigger haptic feedback if vibration is enabled
        if settingsManager.isVibrationEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            print("🟢 Haptic feedback triggered")
        }
        else {
            print("🔴 Haptic feedback disabled")
        }

        guard let tokenPrice = tokenModel.prices.last?.priceUsd else {
            return
        }

        let priceLamps = priceModel.usdToLamports(usd: tokenPrice)

        do {
            try await userModel.sellTokens(price: priceLamps)
            await MainActor.run {
                animationState.showSellBubbles = true
                onSellSuccess?()
            }
        }
        catch {
            notificationHandler.show(
                error.localizedDescription,
                type: .error
            )
        }
    }

    var body: some View {
        VStack {
            if userModel.userId == nil {
                LoginButton(isLoginPresented: $isLoginPresented)
            }
            else if activeTab == "buy" {

                switch userModel.walletState {
                case .connected(_):
                    if let balanceUsd = userModel.balanceLamps,
                        priceModel.lamportsToUsd(lamports: balanceUsd) < 0.1
                    {
                        AirdropButton()
                    }
                    else {
                        HStack(spacing: 16) {
                            Button {
                                showBuySheet = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.aquaGreen)
                                    .padding(12)
                                    .background(Circle().stroke(AppColors.aquaGreen, lineWidth: 1))
                            }
                            
                            // The mint color "Buy $10" button
                            BuyButton(handleBuy: handleBuy)
                        }

                    }
                case .connecting:
                    ConnectingButton()
                default:
                    ConnectButton()
                }
            }
            else {
                SellForm(tokenModel: tokenModel, showBuySheet: $showBuySheet, onSell: handleSell)
                    .padding(.horizontal, 8)

            }
        }
        .padding(8)
        .fullScreenCover(isPresented: $isLoginPresented) {
            RegisterView(isRedirected: true)
                .background(.black)

        }
        .sheet(isPresented: $showBuySheet) {
                BuyFormx(isVisible: $showBuySheet,
                         tokenModel: tokenModel,
                         onBuy: handleBuy)
//                    .transition(.move(edge: .bottom))
//                    .offset(y: -keyboardHeight)
//                    .zIndex(2)
//                    .onAppear {
//                        setupKeyboardNotifications()
//                    }
//                    .onDisappear {
//                        removeKeyboardNotifications()
//                    }
        }
    }
}

private struct LoginButton: View {
    @Binding var isLoginPresented: Bool
    var body: some View {
        Button {
            isLoginPresented = true
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Text("Login to Buy")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .foregroundColor(AppColors.black)
                    .multilineTextAlignment(.center)
            }
            .tubButtonStyle()
        }
    }
}

private struct ConnectButton: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    var body: some View {
        Button(action: {
            Task {
                do {
                    try await privy.embeddedWallet.connectWallet()
                    notificationHandler.show("Connection successful", type: .success)
                }
                catch {
                    notificationHandler.show(error.localizedDescription, type: .error)
                }
            }
        }) {
            HStack(alignment: .center, spacing: 8) {
                Text("Connect to Wallet")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .foregroundColor(AppColors.black)
                    .multilineTextAlignment(.center)
            }
            .tubButtonStyle()
        }
    }
}

private struct ConnectingButton: View {
    var body: some View {
        Button(action: {}) {
            HStack(alignment: .center, spacing: 8) {
                Text("Connecting...")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .foregroundColor(AppColors.black)
                    .multilineTextAlignment(.center)
            }
            .tubButtonStyle()
            .opacity(0.4)
        }.disabled(true)
    }
}

private struct AirdropButton: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @State var showOnrampView = false

    func handleAirdrop() async {
        do {
            try await userModel.performAirdrop()
            notificationHandler.show("Airdrop successful!", type: .success)
        }
        catch {
            notificationHandler.show("Airdrop failed \(error.localizedDescription)", type: .error)
        }
    }
    var body: some View {
        Button(action: {
            Task {
                await handleAirdrop()
            }
        }) {
            HStack(alignment: .center, spacing: 8) {
                Text("Get 1 test SOL")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .foregroundColor(AppColors.black)
                    .multilineTextAlignment(.center)
            }
            .tubButtonStyle()
        }
        .sheet(isPresented: $showOnrampView) {
            CoinbaseOnrampView()
        }
    }
}

private struct BuyButton: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var priceModel: SolPriceModel
    @State private var showOnrampView = false
    @StateObject private var settingsManager = SettingsManager.shared

    var handleBuy: (Double) async -> Void

    var body: some View {
        Button(action: {
            Task {
                await handleBuy(settingsManager.defaultBuyValue)
            }
        }) {
            HStack(alignment: .center, spacing: 8) {
                Text("Buy \(priceModel.formatPrice(usd: settingsManager.defaultBuyValue))")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .foregroundColor(AppColors.black)
                    .multilineTextAlignment(.center)
            }
            .tubButtonStyle()
        }
    }
}

#Preview {
    @Previewable @State var show = false
    @Previewable @State var testAmount = 1.0
    @Previewable @StateObject var notificationHandler = NotificationHandler()
    @Previewable @StateObject var userModel = UserModel.shared
    @Previewable @StateObject var priceModel = SolPriceModel.shared
    ActionButtonsView(
        tokenModel: TokenModel(),
        showBuySheet: $show,
        handleBuy: { _ in },
        onSellSuccess: nil
    )
    .environmentObject(notificationHandler)
    .environmentObject(userModel)
    .environmentObject(priceModel)
}

// MARK: - Equatable Implementation

/// This extension adds custom equality comparison to ActionButtonsView.
/// It's used to optimize SwiftUI's view updates by preventing unnecessary redraws.
extension ActionButtonsView: Equatable {
    static func == (lhs: ActionButtonsView, rhs: ActionButtonsView) -> Bool {
        lhs.tokenModel.token.id == rhs.tokenModel.token.id
    }
}

extension View {
    func tubButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.aquaGreen)
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .inset(by: 0.5)
                    .stroke(AppColors.aquaGreen, lineWidth: 1)
            )
    }
}
