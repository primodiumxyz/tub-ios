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
            switch userModel.walletState {
            case .connected(_):
                if activeTab == "buy" {
                    if let balanceUsd = userModel.balanceLamps,
                        priceModel.lamportsToUsd(lamports: balanceUsd) < 0.1
                    {
                        AirdropButton()
                    }
                    else {
                        HStack(spacing: 16) {
                            CircleButton(
                                icon: "pencil",
                                color: .tubBuyPrimary,
                                iconSize: 20,
                                iconWeight: .bold,
                                action: { showBuySheet = true }
                            )

                            BuyButton(handleBuy: handleBuy)
                        }
                    }
                }
                else {
                    SellButtons(onSell: handleSell)
                }
            case .connecting:
                ConnectingButton()
            default:
                ConnectButton()
            }
        }
        .padding(8)
        .fullScreenCover(isPresented: $isLoginPresented) {
            RegisterView(isRedirected: true)
        }
        .sheet(isPresented: $showBuySheet) {
            BuyFormView(
                isVisible: $showBuySheet,
                tokenModel: tokenModel,
                onBuy: handleBuy
            )
        }
    }
}

private struct LoginButton: View {
    @Binding var isLoginPresented: Bool
    var body: some View {
        PrimaryButton(
            text: "Login to Buy",
            action: { isLoginPresented = true }
        )
    }
}

private struct ConnectButton: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    var body: some View {
        PrimaryButton(
            text: "Connect to wallet",
            action: {
                Task {
                    do {
                        try await privy.embeddedWallet.connectWallet()
                        notificationHandler.show("Connection successful", type: .success)
                    }
                    catch {
                        notificationHandler.show(error.localizedDescription, type: .error)
                    }
                }
            }
        )
    }
}

private struct ConnectingButton: View {
    var body: some View {
        PrimaryButton(
            text: "Connecting...",
            disabled: true,
            action: {}
        )
    }
}

private struct AirdropButton: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @State var showOnrampView = false

    func handleAirdrop() {
        Task {
            do {
                try await userModel.performAirdrop()
                notificationHandler.show("Airdrop successful!", type: .success)
            }
            catch {
                notificationHandler.show("Airdrop failed \(error.localizedDescription)", type: .error)
            }
        }
    }
    var body: some View {
        PrimaryButton(
            text: "Get 1 test SOL",
            action: handleAirdrop
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
            action: {
                Task {
                    await handleBuy(settingsManager.defaultBuyValue)
                }
            }
        )
    }
}

struct SellButtons: View {
    @EnvironmentObject var priceModel: SolPriceModel

    var onSell: () async -> Void

    var body: some View {
        HStack(spacing: 8) {
            // This logic requires refactoring to work so commented out for now
            //                OutlineButton(
            //                    text: "Buy",
            //                    textColor: .tubSellPrimary,
            //                    strokeColor: .tubSellPrimary,
            //                    backgroundColor: .clear,
            //                    action: {}
            //                )

            PrimaryButton(
                text: "Sell",
                backgroundColor: .tubSellPrimary,
                action: {
                    Task {
                        await onSell()
                    }
                }
            )
        }
    }
}

// MARK: - Equatable Implementation

/// This extension adds custom equality comparison to ActionButtonsView.
/// It's used to optimize SwiftUI's view updates by preventing unnecessary redraws.
extension ActionButtonsView: Equatable {
    static func == (lhs: ActionButtonsView, rhs: ActionButtonsView) -> Bool {
        lhs.tokenModel.token.id == rhs.tokenModel.token.id
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var show = false
        @State var testAmount = 1.0
        @StateObject var notificationHandler = NotificationHandler()
        @StateObject var userModel = UserModel.shared
        @StateObject var priceModel = SolPriceModel.shared
        @State var isDark: Bool = true

        func toggleBuySell() {
            if userModel.tokenBalanceLamps ?? 0 > 0 {
                userModel.tokenBalanceLamps = 0
            }
            else {
                userModel.tokenBalanceLamps = 100
            }
        }
        func toggleWalletConnectionState() {
            // You can add your function implementation here
            if userModel.walletState.toString == "connected" {
                userModel.walletState = .disconnected
            }
            else if userModel.walletState == .disconnected {
                userModel.walletState = .connecting
            }
            else if userModel.walletState == .connecting {
                userModel.walletState = .error
            }
            else {
                userModel.walletState = .connected([])
            }
        }

        var body: some View {
            VStack {
                VStack {
                    Text("Modifiers")
                    PrimaryButton(text: "Toggle Buy/Sell") {
                        toggleBuySell()
                    }
                    PrimaryButton(text: "Toggle Connection") {
                        toggleWalletConnectionState()
                    }
                    PrimaryButton(text: "Toggle Dark Mode") {
                        isDark.toggle()
                    }
                }.padding(16).background(.tubBuySecondary)
                Spacer().frame(height: 50)
                ActionButtonsView(
                    tokenModel: TokenModel(),
                    showBuySheet: $show,
                    showBubbles: Binding.constant(false),
                    handleBuy: { _ in },
                    onSellSuccess: nil
                )
            }
            .environmentObject(notificationHandler)
            .environmentObject(userModel)
            .environmentObject(priceModel)
            .preferredColorScheme(isDark ? .dark : .light)
        }
    }

    return PreviewWrapper()
}
