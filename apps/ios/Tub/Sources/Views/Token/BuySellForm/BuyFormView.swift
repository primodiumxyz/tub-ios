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

    @StateObject var txManager = TxManager.shared
    @StateObject var activityManager = LiveActivityManager.shared

    var buttonLoading: Bool {
        txManager.submittingTx
    }

    @EnvironmentObject private var userModel: UserModel
    @State private var buyQuantityUsdString: String = ""
    @State private var buyQuantityUsd: Double = 0
    @State private var isValidInput: Bool = true

    @State private var isDefaultOn: Bool = true  //by default is on

    @ObservedObject private var settingsManager = SettingsManager.shared

    func handleBuy(amountUsdc: Int) {
        guard let priceUsd = tokenModel.prices.last?.priceUsd, priceUsd > 0
        else {
            notificationHandler.show(
                "Something went wrong.",
                type: .error
            )
            return
        }

        let priceUsdc = priceModel.usdToUsdc(usd: priceUsd)
        if isDefaultOn {
            SettingsManager.shared.defaultBuyValueUsdc = amountUsdc
        } 
        Task {
            do {
//                try await TxManager.shared.buyToken(
//                    tokenId: tokenModel.tokenId,
//                    buyAmountUsdc: amountUsdc,
//                    tokenPriceUsdc: priceUsdc
//                )
//                
                if let tokenData = userModel.tokenData[tokenModel.tokenId] {
                    try await activityManager.startTrackingPurchase(
                        mint: tokenModel.tokenId,
                        tokenName: tokenData.metadata.name,
                        symbol: tokenData.metadata.symbol,
                        purchasePriceUsd: priceUsd
                    )
                }
                
                await MainActor.run {
                    self.isVisible = false
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
    
    @State private var updateTimer: Timer?
    static let formHeight: CGFloat = 250

    func updateBuyAmount(_ quantityUsdc: Int) {
        if quantityUsdc == 0 {
            isValidInput = false
            return
        }

        self.buyQuantityUsd = priceModel.usdcToUsd(usdc: quantityUsdc)

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
            loading: buttonLoading,
            action: { handleBuy(amountUsdc: priceModel.usdToUsdc(usd:buyQuantityUsd)) }
        )
        .disabled((userModel.usdcBalance ?? 0) < priceModel.usdToUsdc(usd: buyQuantityUsd))
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
                .onChange(of: buyQuantityUsdString) {
                    var text = buyQuantityUsdString
                    
                    // Validate decimal places
                    let components = text.components(separatedBy: ".")
                    if components.count > 1 {
                        let decimals = components[1]
                        if decimals.count > 2 {
                            text = String(text.dropLast())
                            buyQuantityUsdString = text  
                        }
                    }
                    
                    // Validate if it's a decimal
                    if !text.isEmpty && !text.isDecimal() {
                        text = String(text.dropLast())
                        buyQuantityUsdString = text  
                    }
                    
                    let amount = text.doubleValue
                    if amount > 0 {
                        buyQuantityUsd = amount
                        // Only format if the value has changed
                        buyQuantityUsdString = text
                        
                        // Check if amount exceeds balance
                        let buyQuantityUsdc = priceModel.usdToUsdc(usd: amount)
                        isValidInput = (userModel.usdcBalance ?? 0) >= buyQuantityUsdc
                    } else {
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
                }.opacity(isDefaultOn ? 1 : 0.7)
            }
        }
    }

    let amounts: [Int] = [10, 25, 50, 100]
    private var amountButtons: some View {
        HStack(spacing: 10) {
            ForEach(amounts, id: \.self) { amount in
                let balance = userModel.usdcBalance ?? 0
                let selectedAmountUsd = priceModel.usdcToUsd(usdc: balance * Int(amount) / 100)
                let selected = balance > 0 && selectedAmountUsd == buyQuantityUsd
                CapsuleButton(
                    text: amount == 100 ? "MAX" : "\(amount)%",
                    textColor: .white,
                    backgroundColor: selected ? .tubAltPrimary : .tubAltSecondary,
                    action: {
                        guard let balance = userModel.usdcBalance else { return }
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
        BuyFormView(isVisible: .constant(true), tokenModel: tokenModel)
            .environmentObject(userModel)
            .environmentObject(priceModel)
        
            .preferredColorScheme(.dark)
    }
}
