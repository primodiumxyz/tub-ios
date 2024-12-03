//
//  BuyFormView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SolanaSwift
import SwiftUI

struct WDView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var priceModel: SolPriceModel

    @State private var buyAmountUsdString: String = ""
    @State private var buyAmountUsd: Double = 0
    @State private var recipient: String = ""
    @State private var continueDisabled: Bool = true

    static let formHeight: CGFloat = 250

    private var pages: [AnyView] {
        [
            AnyView(
                AmountSelectView(
                    continueDisabled: $continueDisabled,
                    buyAmountUsdString: $buyAmountUsdString,
                    buyAmountUsd: $buyAmountUsd
                )
            ),
            AnyView(
                RecipientSelectView(
                    continueDisabled: $continueDisabled,
                    recipient: $recipient,
                    buyAmountUsd: buyAmountUsd
                )
            ),
        ]
    }

    @State private var currentPage = 0

    func onComplete() {
        print("complete")
    }

    func handleContinue() {
        if currentPage == pages.count - 1 {
            onComplete()
        }
        else {
            withAnimation {
                currentPage += 1
            }
        }

    }

    private var nextButton: some View {
        HStack {
            if currentPage > 0 {
                PrimaryButton(text: "Back", action: { currentPage -= 1 }).frame(width: 80)
            }
            OutlineButton(
                text: currentPage == pages.count - 1 ? "Confirm" : "Continue",
                textColor: .tubBuyPrimary,
                strokeColor: .tubBuyPrimary,
                backgroundColor: .clear,
                maxWidth: .infinity,
                disabled: continueDisabled,
                action: handleContinue

            )
            .disabled((userModel.balanceLamps ?? 0) < priceModel.usdToLamports(usd: buyAmountUsd))
        }

    }

    var body: some View {
        VStack {
            VStack {
                pages[currentPage].frame(height: 120)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        )
                    )

                nextButton
            }.padding(20)
        }
        .frame(maxHeight: Self.formHeight, alignment: .leading)
        .cornerRadius(30)
        .presentationDetents([.height(Self.formHeight)])
        .presentationBackground(.clear)
        .background(Gradients.cardBgGradient)
    }

}

struct AmountSelectView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var notificationHandler: NotificationHandler
    @EnvironmentObject private var userModel: UserModel

    @Binding var continueDisabled: Bool
    @Binding var buyAmountUsdString: String
    @Binding var buyAmountUsd: Double

    func updateBuyAmount(_ amountLamps: Int) {
        if amountLamps == 0 {
            continueDisabled = true
            return
        }

        // Add a tiny buffer for floating point precision
        buyAmountUsd = priceModel.lamportsToUsd(lamports: amountLamps)

        // Format to 2 decimal places, rounding down
        buyAmountUsdString = String(format: "%.2f", floor(buyAmountUsd * 100) / 100)
        continueDisabled = false
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            numberInput
            amountButtons
        }
        .onAppear {
            let buyAmountLamps = priceModel.usdToLamports(usd: buyAmountUsd)
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
                    text: $buyAmountUsdString,
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
                            buyAmountUsd = amount
                            // Only format if the value has changed
                            buyAmountUsdString = text
                        }
                        continueDisabled = false
                    }
                    else {
                        buyAmountUsd = 0
                        continueDisabled = true
                    }
                }
                .font(.sfRounded(size: .xl5, weight: .semibold))
                .foregroundStyle(continueDisabled ? .tubError : .tubText)
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
                let selected = balance > 0 && selectedAmountUsd == buyAmountUsd
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
    @Binding var continueDisabled: Bool
    @Binding var recipient: String
    @State var showError: Bool = false
    let buyAmountUsd: Double

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

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Sending")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundStyle(.tubText.opacity(0.7))

                    Text("$\(String(format: "%.2f", buyAmountUsd))")
                        .font(.sfRounded(size: .lg, weight: .bold))
                        .foregroundStyle(.tubText)

                    Text("to")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundStyle(.tubText.opacity(0.7))

                }
                TextField(
                    "",
                    text: $recipient,
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
            let isValid = validateAddress(recipient)
            continueDisabled = !isValid
            showError = !recipient.isEmpty && !isValid

        }
        .onChange(of: recipient) {
            let isValid = validateAddress(recipient)
            continueDisabled = !isValid
            showError = !recipient.isEmpty && !isValid
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

    WDView()
        .environmentObject(userModel)
        .environmentObject(priceModel)
        .preferredColorScheme(.light)
}
