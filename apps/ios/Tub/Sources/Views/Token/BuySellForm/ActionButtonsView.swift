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
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var isLoginPresented = false

    @Binding var showBubbles: Bool

    var handleBuy: (Double) async -> Void
    var onSellSuccess: (() -> Void)?

    init(
        tokenModel: TokenModel,
        showBuySheet: Binding<Bool>,
        showBubbles: Binding<Bool>,
        handleBuy: @escaping (Double) async -> Void,
        onSellSuccess: (() -> Void)? = nil
    ) {
        self.tokenModel = tokenModel
        self._showBuySheet = showBuySheet
        self._showBubbles = showBubbles
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
        }

        guard let tokenPrice = tokenModel.prices.last?.priceUsd else {
            return
        }

        let priceLamps = priceModel.usdToLamports(usd: tokenPrice)

        do {
            try await userModel.sellTokens(price: priceLamps)
            await MainActor.run {
                showBubbles = true
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
                            CircleButton(
                                icon: "pencil",
                                color: Color("aquaGreen"),
                                iconSize: 20,
                                iconWeight: .bold,
                                action: { showBuySheet = true }
                            )
                            
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
            BuyFormView(isVisible: $showBuySheet,
                        tokenModel: tokenModel,
                        onBuy: handleBuy)
        }
    }
}

private struct LoginButton: View {
    @Binding var isLoginPresented: Bool
    var body: some View {
        PrimaryButton(
            text: "Login to Buy",
            textColor: Color.black,
            backgroundColor: Color("aquaGreen"),
            strokeColor: Color("aquaGreen"),
            maxWidth: .infinity,
            action: { isLoginPresented = true }
        )
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
                    .foregroundColor(Color.black)
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
                    .foregroundColor(Color.black)
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
        PrimaryButton(
            text: "Get 1 test SOL",
            textColor: Color.black,
            backgroundColor: Color("aquaGreen"),
            strokeColor: Color("aquaGreen"),
            maxWidth: .infinity,
            action: {
                Task {
                    await handleAirdrop()
                }
            }
        )
        .padding(.horizontal, 8)
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
        PrimaryButton(
            text: "Buy \(priceModel.formatPrice(usd: settingsManager.defaultBuyValue))",
            textColor: Color.black,
            backgroundColor: Color("aquaGreen"),
            action: {
                Task {
                    await handleBuy(settingsManager.defaultBuyValue)
                }
            }
        )
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
        showBubbles: Binding.constant(false),
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
            .background(Color("aquaGreen"))
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .inset(by: 0.5)
                    .stroke(Color("aquaGreen"), lineWidth: 1)
            )
    }
}
