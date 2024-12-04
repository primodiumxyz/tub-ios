//
//  BuyFormView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct BuyFormView: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var notificationHandler: NotificationHandler
    @ObservedObject var tokenModel: TokenModel
    var onBuy: (Double) async -> Void

    @EnvironmentObject private var userModel: UserModel
    @State private var buyAmountUsdString: String = ""
    @State private var buyAmountUsd: Double = 0
    @State private var isValidInput: Bool = true

    @State private var isDefaultOn: Bool = true  //by default is on

    @ObservedObject private var settingsManager = SettingsManager.shared

    static let formHeight: CGFloat = 250

    private func handleBuy() {
        guard let balance = userModel.balanceLamps else { return }
        // Use 10 as default if no amount is entered
        let amountToUse = buyAmountUsdString.isEmpty ? 10.0 : buyAmountUsd

        let buyAmountLamps = priceModel.usdToLamports(usd: amountToUse)

        // Check if the user has enough balance
        if balance >= buyAmountLamps {
            if isDefaultOn {
                settingsManager.defaultBuyValue = amountToUse
            }
            Task {
                await onBuy(amountToUse)
            }
        }
        else {
            notificationHandler.show("Insufficient Balance", type: .error)
        }
    }

    func updateBuyAmount(_ amountLamps: Int) {
        if amountLamps == 0 {
            isValidInput = false
            return
        }

        // Add a tiny buffer for floating point precision
        buyAmountUsd = priceModel.lamportsToUsd(lamports: amountLamps)

        // Format to 2 decimal places, rounding down
        buyAmountUsdString = String(format: "%.2f", floor(buyAmountUsd * 100) / 100)
        isValidInput = true
    }

    func resetForm() {
        buyAmountUsdString = ""
        buyAmountUsd = 0
        isValidInput = true
        isDefaultOn = true
    }

    var body: some View {
        VStack {
            formContent
                .padding()

        }
        .background(Gradients.cardBgGradient)
        .onAppear { resetForm() }
        .dismissKeyboardOnTap()
        .cornerRadius(30)
        .presentationDetents([.height(Self.formHeight)])
        .presentationBackground(.clear)
    }

    private var formContent: some View {
        VStack {
            HStack {
                IconButton(
                    icon: "xmark",
                    color: .tubBuyPrimary,
                    size: 18,
                    action: { isVisible = false }
                )
                Spacer()
                defaultToggle
            }

            VStack(alignment: .center, spacing: 20) {
                numberInput
                amountButtons
                buyButton
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }

    private var buyButton: some View {
        OutlineButton(
            text: "Buy",
            textColor: .tubBuyPrimary,
            strokeColor: .tubBuyPrimary,
            backgroundColor: .clear,
            maxWidth: .infinity,
            action: handleBuy
        )
        .disabled((userModel.balanceLamps ?? 0) < priceModel.usdToLamports(usd: buyAmountUsd))
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
                    prompt: Text("10", comment: "placeholder")
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
                        isValidInput = true
                    }
                    else {
                        buyAmountUsd = 0
                        isValidInput = false
                    }
                }
                .font(.sfRounded(size: .xl5, weight: .semibold))
                .foregroundStyle(isValidInput ? .tubText : .tubError)
                .frame(minWidth: 50)
                .fixedSize()
                Spacer()
            }
            .frame(maxWidth: 300)
            .padding(.horizontal)
        }
    }

    private var defaultToggle: some View {
        HStack {
            Spacer()
            Button(action: {
                isDefaultOn.toggle()
            }) {
                HStack(spacing: 4) {
                    Text("Set Default")
                        .font(.sfRounded(size: .base, weight: .regular))
                        .foregroundStyle(isDefaultOn ? .tubText : .tubNeutral)

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(isDefaultOn ? .tubSuccess : .tubNeutral)
                }
            }
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

func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
)
    -> Bool
{
    guard !string.isEmpty else {
        return true
    }

    let currentText = textField.text ?? ""
    let replacementText = (currentText as NSString).replacingCharacters(in: range, with: string)

    return replacementText.isDecimal()
}

extension String {
    func isDecimal() -> Bool {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.locale = Locale.current
        return formatter.number(from: self) != nil
    }
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        return formatter
    }()

    var doubleValue: Double {
        // Special handling for 3 decimal places with comma
        if self.components(separatedBy: CharacterSet(charactersIn: ",")).last?.count == 3 {
            String.numberFormatter.decimalSeparator = ","
            if let result = String.numberFormatter.number(from: self) {
                return result.doubleValue
            }
        }

        // Try with dot as decimal separator
        String.numberFormatter.decimalSeparator = "."
        if let result = String.numberFormatter.number(from: self) {
            return result.doubleValue
        }

        // Try with comma as decimal separator
        String.numberFormatter.decimalSeparator = ","
        if let result = String.numberFormatter.number(from: self) {
            return result.doubleValue
        }

        return 0
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

    BuyFormView(isVisible: .constant(true), tokenModel: tokenModel, onBuy: { _ in })
        .environmentObject(userModel)
        .environmentObject(priceModel)
        .preferredColorScheme(.light)
}
