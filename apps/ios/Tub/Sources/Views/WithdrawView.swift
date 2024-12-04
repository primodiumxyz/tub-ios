//
//  BuyFormView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SolanaSwift
import SwiftUI

class WithdrawModel: ObservableObject {
    var walletAddress: String? = nil

    @Published var buyAmountUsdString: String = ""
    @Published var buyAmountUsd: Double = 0
    @Published var recipient: String = ""
    @Published var continueDisabled: Bool = true
    @Published var currentPage = 0

    func initialize(walletAddress: String) {
        self.walletAddress = walletAddress
    }

    func validateAddress(_ address: String) -> Bool {
        if address.isEmpty { return false }
        do {
            let _ = try PublicKey(string: address)
            return true
        }
        catch {
            return false
        }
    }

    func onComplete() async throws -> String {
        guard let walletAddress else {
            throw TubError.somethingWentWrong(reason: "Cannot transfer: not logged in")
        }

        if !validateAddress(recipient) {
            throw TubError.somethingWentWrong(reason: "Invalid recipient address")
        }

        let buyAmountUsdc = Int(buyAmountUsd * 1e6)

        do {
            let txId = try await Network.shared.transferUsdc(
                fromAddress: walletAddress,
                toAddress: recipient,
                amount: buyAmountUsdc
            )
            return txId
        }
        catch {
            throw error
        }
    }

}

struct WithdrawView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var notificationHandler: NotificationHandler

    @StateObject private var vm = WithdrawModel()

    static let formHeight: CGFloat = 400

    func handleContinue() {
        let complete = vm.currentPage == pages.count - 1
        if complete {
            Task {
                do {
                    let _ = try await vm.onComplete()
                    notificationHandler.show("Transfer successful!", type: .success)
                }
                catch {
                    notificationHandler.show(error.localizedDescription, type: .error)
                }
            }
        }
        else {
            withAnimation {
                vm.currentPage += 1
            }
        }
    }

    var pages: [AnyView] {
        [
            AnyView(
                AmountSelectView(
                    vm: vm
                )
            ),
            AnyView(
                RecipientSelectView(
                    vm: vm
                )
            ),
        ]
    }

    private var nextButton: some View {
        HStack {
            if vm.currentPage > 0 {
                PrimaryButton(text: "Back", action: { vm.currentPage -= 1 }).frame(width: 80)
            }
            OutlineButton(
                text: vm.currentPage == pages.count - 1 ? "Confirm" : "Continue",
                textColor: .tubBuyPrimary,
                strokeColor: .tubBuyPrimary,
                backgroundColor: .clear,
                maxWidth: .infinity,
                disabled: vm.continueDisabled,
                action: handleContinue

            )
            .disabled((userModel.balanceLamps ?? 0) < priceModel.usdToLamports(usd: vm.buyAmountUsd))
        }

    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30).fill(Color(UIColor.systemBackground))
                .zIndex(0).frame(maxWidth: .infinity, maxHeight: Self.formHeight)
            VStack {
                VStack {
                    pages[vm.currentPage].frame(height: 150)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            )
                        )

                    nextButton
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: Self.formHeight)
            .zIndex(1)
            .background(Gradients.cardBgGradient)
            .cornerRadius(30)
        }
        .frame(maxHeight: Self.formHeight, alignment: .leading)
        .presentationDetents([.height(Self.formHeight)])
        .presentationBackground(.clear)
        .onAppear {
            guard let walletAddress = userModel.walletAddress else { return }
            vm.initialize(walletAddress: walletAddress)
        }
        .onChange(of: userModel.walletAddress) {
            guard let walletAddress = userModel.walletAddress else { return }
            vm.initialize(walletAddress: walletAddress)
        }
    }

}

struct AmountSelectView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var notificationHandler: NotificationHandler
    @EnvironmentObject private var userModel: UserModel

    @ObservedObject var vm: WithdrawModel

    func updateBuyAmount(_ amountLamps: Int) {
        if amountLamps == 0 {
            vm.continueDisabled = true
            return
        }

        // Add a tiny buffer for floating point precision
        vm.buyAmountUsd = priceModel.lamportsToUsd(lamports: amountLamps)

        // Format to 2 decimal places, rounding down
        vm.buyAmountUsdString = String(format: "%.2f", floor(vm.buyAmountUsd * 100) / 100)
        vm.continueDisabled = false
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            numberInput
            amountButtons
        }
        .onAppear {
            let buyAmountLamps = priceModel.usdToLamports(usd: vm.buyAmountUsd)
            updateBuyAmount(buyAmountLamps)
        }
    }

    private var numberInput: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Spacer()
                Text("$")
                    .font(.sfRounded(size: .xl4, weight: .bold))
                    .foregroundStyle(.tubText)

                TextField(
                    "",
                    text: $vm.buyAmountUsdString,
                    prompt: Text("10.00", comment: "placeholder")
                        .foregroundStyle(.tubText.opacity(0.3))
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
                .textFieldStyle(PlainTextFieldStyle())
                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification)) { obj in
                    guard let textField = obj.object as? UITextField else { return }

                    if let text = textField.text {
                        // Validate decimal places
                        let components = text.components(separatedBy: ".")
                        if components.count > 1 {
                            let decimals = components[1]
                            if decimals.count > 2 {
                                textField.text = String(text.dropLast())
                            }
                        }

                        // Validate if it's a decimal
                        if !text.isEmpty && !text.isDecimal() {
                            textField.text = String(text.dropLast())
                        }

                        let amount = text.doubleValue
                        if amount > 0 {
                            vm.buyAmountUsd = amount
                            // Only format if the value has changed
                            vm.buyAmountUsdString = text
                        }
                        vm.continueDisabled = false
                    }
                    else {
                        vm.buyAmountUsd = 0
                        vm.continueDisabled = true
                    }
                }
                .font(.sfRounded(size: .xl5, weight: .semibold))
                .foregroundStyle(vm.continueDisabled ? .tubError : .tubText)
                .frame(minWidth: 50)
                .fixedSize()
                Spacer()
            }
            .frame(maxWidth: 300)
            .padding(.horizontal)
        }
    }

    private var amountButtons: some View {
        HStack(spacing: 10) {
            ForEach([10, 25, 50, 100], id: \.self) { amount in
                let balance = userModel.balanceLamps ?? 0
                let selectedAmountUsd = priceModel.lamportsToUsd(lamports: balance * amount / 100)
                let selected = balance > 0 && selectedAmountUsd == vm.buyAmountUsd
                CapsuleButton(
                    text: amount == 100 ? "MAX" : "\(amount)%",
                    textColor: .white,
                    backgroundColor: selected ? .tubAltPrimary : .tubAltSecondary,
                    action: {
                        guard let balance = userModel.balanceLamps else { return }
                        updateBuyAmount(balance * amount / 100)
                    }
                )
            }
        }
    }
}

struct RecipientSelectView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @State var showError: Bool = false
    @ObservedObject var vm: WithdrawModel

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Sending")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundStyle(.tubText.opacity(0.7))

                    Text("$\(String(format: "%.2f", vm.buyAmountUsd))")
                        .font(.sfRounded(size: .lg, weight: .bold))
                        .foregroundStyle(.tubText)

                    Text("to")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundStyle(.tubText.opacity(0.7))

                }
                TextField(
                    "",
                    text: $vm.recipient,
                    prompt: Text("Enter Solana address")
                        .foregroundStyle(.tubText.opacity(0.3))
                )

                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .font(.sfRounded(size: .lg, weight: .regular))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.tubPurple.opacity(0.5), lineWidth: 1)
                )

                Text(showError ? "Solana Address is invalid" : " ").font(.sfRounded(size: .sm, weight: .regular))
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            let isValid = vm.validateAddress(vm.recipient)
            vm.continueDisabled = !isValid
            showError = !vm.recipient.isEmpty && !isValid

        }
        .onChange(of: vm.recipient) {
            let isValid = vm.validateAddress(vm.recipient)
            vm.continueDisabled = !isValid
            showError = !vm.recipient.isEmpty && !isValid
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    @Previewable @StateObject var priceModel = {
        let model = SolPriceModel.shared
        spoofPriceModelData(model)
        return model
    }()

    @Previewable @StateObject var userModel = UserModel.shared

    let tokenModel = {
        let model = TokenModel()
        spoofTokenModelData(model)
        return model
    }()

    VStack {
        WithdrawView()
            .environmentObject(userModel)
            .environmentObject(priceModel)
            .preferredColorScheme(.light)
    }.background(.red)
}
