//
//  BuyForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct BuyForm: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var notificationHandler: NotificationHandler
    @ObservedObject var tokenModel: TokenModel
    var onBuy: (Double) async -> Void

    @EnvironmentObject private var userModel: UserModel
    @State private var buyAmountUsdString: String = ""
    @State private var buyAmountUsd: Double = 0
    @State private var isValidInput: Bool = true

    @State private var dragOffset: CGFloat = 0.0
    @State private var slideOffset: CGFloat = UIScreen.main.bounds.height
    @State private var animatingSwipe: Bool = false
    @State private var isClosing: Bool = false

    @State private var isKeyboardActive: Bool = false
    @State private var keyboardHeight: CGFloat = 0.0
    private let keyboardAdjustment: CGFloat = 220

    @State private var isDefaultOn: Bool = true  //by default is on

    @ObservedObject private var settingsManager = SettingsManager.shared

    @State private var updateTimer: Timer?
    @State private var amountLamps: Int = 0

    @MainActor
    private func handleBuy() async {
        guard let balance = userModel.balanceLamps else { return }
        // Use 10 as default if no amount is entered
        let amountToUse = buyAmountUsdString.isEmpty ? 10.0 : buyAmountUsd

        let buyAmountLamps = priceModel.usdToLamports(usd: amountToUse)

        // Check if the user has enough balance
        if balance >= buyAmountLamps {
            if isDefaultOn {
                settingsManager.defaultBuyValue = amountToUse
            }
            await onBuy(amountToUse)
        }
        else {
            notificationHandler.show("Insufficient Balance", type: .error)
        }
    }

    func updateTxData(buyAmountUsd: Double) {
        updateTimer?.invalidate()

        // only update the amountLamps if the user hasnt updated the amount for more than 0.5 second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            let amountLamps = priceModel.usdToLamports(usd: buyAmountUsd)
            try! TxManager.shared.updateTxData(quantity: amountLamps)
        }

    }

    func updateBuyAmount(_ amountLamps: Int) {
        if amountLamps == 0 {
            isValidInput = false
            return
        }

        // Add a tiny buffer for floating point precision
        buyAmountUsd = priceModel.lamportsToUsd(lamports: amountLamps)
        updateTxData(buyAmountUsd: buyAmountUsd)

        // Format to 2 decimal places, rounding down
        buyAmountUsdString = String(format: "%.2f", floor(buyAmountUsd * 100) / 100)
        isValidInput = true
    }

    func resetForm() {
        buyAmountUsdString = ""
        buyAmountUsd = 0
        isValidInput = true
        animatingSwipe = false
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
        .offset(y: max(dragOffset, slideOffset - keyboardHeight + (isKeyboardActive ? keyboardAdjustment : 0)))
        .gesture(dragGesture)
        .onAppear(perform: animateAppearance)
        .onChange(of: isVisible, perform: handleVisibilityChange)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardActive = false
        }
        .dismissKeyboardOnTap()
    }

    private var formContent: some View {
        VStack {
            defaultToggle
            VStack(alignment: .center, spacing: 20) {
                numberInput
                amountButtons
                buyButton
            }
        }
        .padding(8)
        .frame(height: 300)
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
        .disabled((userModel.balanceLamps ?? 0) < priceModel.usdToLamports(usd: buyAmountUsd))
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
                    text: $buyAmountUsdString,
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
                            buyAmountUsd = amount
                            updateTxData(buyAmountUsd: buyAmountUsd)
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
                .font(.sfRounded(size: .xl5, weight: .bold))
                .foregroundStyle(isValidInput ? Color.white : Color.red)
                .frame(minWidth: 50)
                .fixedSize()
                .onTapGesture {
                    isKeyboardActive = true
                }
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
                        guard let balance = userModel.balanceLamps else { return }
                        updateBuyAmount(balance * amount / 100)
                    }
                )
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                handleDragGestureEnd(value)
            }
    }

    private func handleDragGestureEnd(_ value: DragGesture.Value) {
        let threshold: CGFloat = 100
        let verticalAmount = value.translation.height

        if verticalAmount > threshold && !animatingSwipe {
            withAnimation(.easeInOut(duration: 0.4)) {
                dragOffset = UIScreen.main.bounds.height
            }
            animatingSwipe = true
            isClosing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isVisible = false  // Close the form
            }
        }
        else {
            withAnimation(.easeInOut(duration: 0.3)) {
                dragOffset = 0
            }
        }
    }

    private func animateAppearance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
            slideOffset = 150
        }
    }

    private func handleVisibilityChange(_ newValue: Bool) {
        if newValue {
            // Reset when becoming visible
            isClosing = false
            dragOffset = 0
            slideOffset = 150
            resetForm()
        }
        else if !isClosing {
            // Only animate closing if not already closing from gesture
            withAnimation(.easeInOut(duration: 0.4)) {
                dragOffset = UIScreen.main.bounds.height
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
