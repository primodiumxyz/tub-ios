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
    @State private var buyQuantityUsdString: String = ""
    @State private var buyQuantityUsd: Double = 0
    @State private var isValidInput: Bool = true

    @State private var isDefaultOn: Bool = true  //by default is on

    @ObservedObject private var settingsManager = SettingsManager.shared

    @State private var updateTimer: Timer?
    static let formHeight: CGFloat = 250

    @MainActor
    private func handleBuy() async {
        guard let balanceUsdc = userModel.balanceUsdc else { return }
        // Use 10 as default if no amount is entered
        let buyQuantityUsd = buyQuantityUsdString.isEmpty ? 10.0 : self.buyQuantityUsd

        let buyQuantityUsdc = priceModel.usdToUsdc(usd: buyQuantityUsd)

        // Check if the user has enough balance
        if balanceUsdc >= buyQuantityUsdc {
            if isDefaultOn {
                settingsManager.defaultBuyValueUsd = buyQuantityUsd
            }
            await onBuy(buyQuantityUsd)
        }
        else {
            notificationHandler.show("Insufficient Balance", type: .error)
        }
    }

    func updateTxData(buyQuantityUsd: Double) {
        updateTimer?.invalidate()

        // only update the amountLamps if the user hasnt updated the amount for more than 0.5 second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            let buyQuantityUsdc = priceModel.usdToUsdc(usd: buyQuantityUsd)
            Task {
                try! await TxManager.shared.updateTxData(sellQuantity: buyQuantityUsdc)
            }
        }

    }

    func updateBuyAmount(_ quantityUsdc: Int) {
        if quantityUsdc == 0 {
            isValidInput = false
            return
        }

        self.buyQuantityUsd = priceModel.usdcToUsd(usdc: quantityUsdc)
        updateTxData(buyQuantityUsd: self.buyQuantityUsd)

        self.buyQuantityUsdString = String(format: "%.2f", floor(buyQuantityUsd * 100) / 100)
        isValidInput = true
    }

    func resetForm() {
        buyQuantityUsdString = ""
        buyQuantityUsd = 0
        isValidInput = true
        isDefaultOn = true
    }

    var body: some View {
        VStack {
            formContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(AppColors.darkGreenGradient)
        .cornerRadius(26)
        .onAppear { resetForm() }
        .dismissKeyboardOnTap()
        .presentationDetents([.height(Self.formHeight)])
        .presentationBackground(.clear)
    }

    private var formContent: some View {
        VStack {
            HStack {
                Button {
                    isVisible = false
                } label: {
                    Image(systemName: "xmark")
                }
                Spacer()
                defaultToggle
            }

            VStack(alignment: .center, spacing: 20) {
                numberInput
                amountButtons
                buyButton
            }
        }
        .frame(height: Self.formHeight)
        .padding(.horizontal, 8)
    }

    private var buyButton: some View {
        OutlineButton(
            text: "Buy",
            textColor: Color("aquaGreen"),
            strokeColor: Color("aquaGreen"),
            backgroundColor: .clear,
            maxWidth: .infinity,
            action: {
                Task {
                    await handleBuy()
                }
            }
        )
        .disabled((userModel.balanceUsdc ?? 0) < priceModel.usdToUsdc(usd: buyQuantityUsd))
    }

    private var numberInput: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Spacer()
                Text("$")
                    .font(.sfRounded(size: .xl4, weight: .bold))
                    .foregroundStyle(Color.white)

                TextField(
                    "",
                    text: $buyQuantityUsdString,
                    prompt: Text("10", comment: "placeholder")
                        .foregroundStyle(Color.white.opacity(0.3))
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
                            buyQuantityUsd = amount
                            updateTxData(buyQuantityUsd: buyQuantityUsd)
                            // Only format if the value has changed
                            buyQuantityUsdString = text
                        }
                        isValidInput = true
                    }
                    else {
                        buyQuantityUsd = 0
                        isValidInput = false
                    }
                }
                .font(.sfRounded(size: .xl5, weight: .bold))
                .foregroundStyle(isValidInput ? Color.white : Color.red)
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
                        .foregroundStyle(isDefaultOn ? Color.white : Color.gray)

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(isDefaultOn ? Color.green : Color.gray)
                }
            }
        }
    }

    private var amountButtons: some View {
        HStack(spacing: 10) {
            ForEach([10, 25, 50, 100], id: \.self) { amount in
                CapsuleButton(
                    text: amount == 100 ? "MAX" : "\(amount)%",
                    action: {
                        guard let balanceUsdc = userModel.balanceUsdc else { return }
                        updateBuyAmount(balanceUsdc * amount / 100)
                    }
                )
            }
        }
    }

}

func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String)
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
