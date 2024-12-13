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
    var onBuy: () async -> Void

    @EnvironmentObject private var userModel: UserModel
    @State private var buyQuantityUsdString: String = ""
    @State private var buyQuantityUsd: Double = 0
    @State private var isValidInput: Bool = true

    @State private var isDefaultOn: Bool = true  //by default is on

    @ObservedObject private var settingsManager = SettingsManager.shared

    @State private var updateTimer: Timer?
    static let formHeight: CGFloat = 250

    private func handleBuy() {
        guard let balanceUsdc = userModel.balanceUsdc else { return }
        // Use 10 as default if no amount is entered
        let buyQuantityUsd = buyQuantityUsdString.isEmpty ? 10.0 : self.buyQuantityUsd

        let buyQuantityUsdc = priceModel.usdToUsdc(usd: buyQuantityUsd)

        // Check if the user has enough balance
        if balanceUsdc >= buyQuantityUsdc {
            if isDefaultOn {
                settingsManager.defaultBuyValueUsdc = buyQuantityUsdc
            }
            Task {
                await onBuy()
            }
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
        ZStack(alignment: .top) {
            Rectangle()
                .foregroundStyle(.clear)
                .frame(height: Self.formHeight)
                .background(.tubTextInverted)
                .cornerRadius(30)
                .zIndex(0)
            
            formContent
                .zIndex(1)
        }
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
        .padding()
        .background(Gradients.cardBgGradient)
        .onAppear { resetForm() }
        .cornerRadius(30)
        .presentationDetents([.height(Self.formHeight)])
        .presentationBackground(.clear)
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
        .disabled((userModel.balanceUsdc ?? 0) < priceModel.usdToUsdc(usd: buyQuantityUsd))
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
                    text: $buyQuantityUsdString,
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

    let amounts: [Int] = [10, 25, 50, 100]
    private var amountButtons: some View {
        HStack(spacing: 10) {
            ForEach(amounts, id: \.self) { amount in
                let balance = userModel.balanceUsdc ?? 0
                let selectedAmountUsd = priceModel.usdcToUsd(usdc: balance * Int(amount) / 100)
                let selected = balance > 0 && selectedAmountUsd == buyQuantityUsd
                CapsuleButton(
                    text: amount == 100 ? "MAX" : "\(amount)%",
                    textColor: .white,
                    backgroundColor: selected ? .tubAltPrimary : .tubAltSecondary,
                    action: {
                        guard let balance = userModel.balanceUsdc else { return }
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
        spoofTokenModelData(userModel: userModel, tokenModel : model)
        return model
    }()

    ZStack {
        Color.red
        BuyFormView(isVisible: .constant(true), tokenModel: tokenModel, onBuy: { })
            .environmentObject(userModel)
            .environmentObject(priceModel)
        
            .preferredColorScheme(.dark)
    }
}
