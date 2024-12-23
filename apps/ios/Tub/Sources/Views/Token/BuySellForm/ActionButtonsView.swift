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
    
    @State var showBuySheet = false
    @StateObject private var settingsManager = SettingsManager.shared

    init(
        tokenModel: TokenModel
    ) {
        self.tokenModel = tokenModel
    }

    var balanceToken: Int {
        userModel.tokenData[tokenModel.tokenId]?.balanceToken ?? 0
    }
    
    var activeTab: PurchaseState {
        return balanceToken > 0 ? .sell : .buy
    }

    func handleBuy() {
        guard let priceUsd = tokenModel.prices.last?.priceUsd, priceUsd > 0
        else {
            notificationHandler.show(
                "Something went wrong.",
                type: .error
            )
            return
        }

        let priceUsdc = priceModel.usdToUsdc(usd: priceUsd)
        let buyAmountUsdc = SettingsManager.shared.defaultBuyValueUsdc

        Task {
            do {
                try await TxManager.shared.buyToken(
                    tokenId: tokenModel.tokenId, buyAmountUsdc: buyAmountUsdc, tokenPriceUsdc: priceUsdc
                )
                await MainActor.run {
                    showBuySheet = false
                    notificationHandler.show(
                        "Successfully bought tokens!",
                        type: .success
                    )
                }
            }
            catch {
                notificationHandler.show(
                    error.localizedDescription,
                    type: .error
                )
            }
        }
    }
    
    

    func handleSell() async {
        // Only trigger haptic feedback if vibration is enabled
        if settingsManager.isVibrationEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        guard let tokenPriceUsd = tokenModel.prices.last?.priceUsd else {
            return
        }

        do {
            try await TxManager.shared.sellToken(tokenId: tokenModel.tokenId, tokenPriceUsd: tokenPriceUsd)
            await MainActor.run {
                BubbleManager.shared.trigger()
                notificationHandler.show("Successfully sold tokens!", type: .success)
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
                LoginButton()
            }
            else {
                switch userModel.walletState {
                case .connected(_):
                    if activeTab == .buy {
                        if priceModel.usdcToUsd(usdc: userModel.usdcBalance ?? 0) < 0.1
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
                                    disabled: !tokenModel.isReady,
                                    action: { showBuySheet = true }
                                )

                                BuyButton(handleBuy: handleBuy, disabled: !tokenModel.isReady)
                            }
                        }
                    }
                    else {
                        SellButton(onSell: handleSell, disabled: !tokenModel.isReady)
                    }
                case .connecting:
                    ConnectingButton()
                default:
                    ConnectButton()
                }
            }
        }
        .padding(.horizontal, 8)
        .sheet(isPresented: $showBuySheet) {
            BuyFormView(
                isVisible: $showBuySheet,
                tokenModel: tokenModel
            )
        }
    }
}

private struct LoginButton: View {
    @State var isLoginPresented = false
    var body: some View {
        PrimaryButton(
            text: "Login to Buy",
            action: { isLoginPresented = true }
        )
        .navigationDestination(isPresented: $isLoginPresented) {
            AccountView()
        }
    }
}

private struct ConnectButton: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    func handleConnect() {
        Task {
            do {
                do {
                    try await privy.embeddedWallet.connectWallet()
                } catch {
                    let _ = try await privy.embeddedWallet.createWallet(chainType: .solana)
                }
                notificationHandler.show("Connection successful", type: .success)
            }
            catch {
                notificationHandler.show(error.localizedDescription, type: .error)
            }
        }
    }

    var body: some View {
        PrimaryButton(
            text: "Connect to wallet",
            action: handleConnect
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

    var body: some View {
        PrimaryButton(
            text: "Deposit to buy",
            action: { showOnrampView.toggle() }
        )
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
    @StateObject private var txManager = TxManager.shared

    var handleBuy: () -> Void
    var disabled = false

    var body: some View {
        PrimaryButton(
            text: "Buy \(priceModel.formatPrice(usdc: settingsManager.defaultBuyValueUsdc))",
            disabled: disabled,
            loading: txManager.submittingTx,
            action: handleBuy
        )
    }
}

struct SellButton: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @StateObject private var txManager = TxManager.shared
    var onSell: () async -> Void
    var disabled: Bool = false

    var body: some View {
            PrimaryButton(
                text: "Sell",
                textColor: .white,
                backgroundColor: .tubSellPrimary,
                disabled: disabled,
                loading: txManager.submittingTx,
                action: {
                    Task {
                        await onSell()
                    }
                }
            )
    }
}

// MARK: - Equatable Implementation

/// This extension adds custom equality comparison to ActionButtonsView.
/// It's used to optimize SwiftUI's view updates by preventing unnecessary redraws.
extension ActionButtonsView: Equatable {
    static func == (lhs: ActionButtonsView, rhs: ActionButtonsView) -> Bool {
        lhs.tokenModel.tokenId == rhs.tokenModel.tokenId
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var show = false
        @State var testAmount = 1.0
        @StateObject var notificationHandler = NotificationHandler()
        var userModel = {
            let model = UserModel.shared
            
            Task {
                await model.updateTokenData(mint: USDC_MINT, balance: 100 * Int(1e6))
            }
            return model
        }()

        var priceModel = {
            let model = SolPriceModel.shared
            spoofPriceModelData(model)
            return model
        }()

        @State var isDark: Bool = true

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

        var tokenModel = {
            let model = TokenModel()
            model.isReady = true
            return model
        }()
        
            
        var body: some View {
            VStack {
                VStack {
                    Text("Modifiers")
                    PrimaryButton(text: "Toggle Connection") {
                        toggleWalletConnectionState()
                    }
                    PrimaryButton(text: "Toggle Dark Mode") {
                        isDark.toggle()
                    }
                }.padding(16).background(.tubBuySecondary)
                Spacer().frame(height: 50)
                ActionButtonsView(
                    tokenModel: tokenModel
                )
                .border(.red)
            }
            .environmentObject(notificationHandler)
            .environmentObject(userModel)
            .environmentObject(priceModel)
            .preferredColorScheme(isDark ? .dark : .light)
        }
    }

    return PreviewWrapper()
}
