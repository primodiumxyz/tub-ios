//
//  BuyFormView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

class WithdrawModel: ObservableObject {
    var walletAddress: String? = nil

    @Published var buyAmountUsdString: String = ""
    @Published var buyAmountUsd: Double = 0
    @Published var recipient: String = ""
    @Published var continueDisabled: Bool = true
    @Published var sending: Bool = false

    func initialize(walletAddress: String) {
        self.walletAddress = walletAddress
    }

    func validateAddress(_ address: String) -> Bool {
        // Check if address is empty
        guard !address.isEmpty else { return false }

        // Check length (Solana addresses are 32-byte public keys encoded in base58, resulting in 44 characters)
        guard address.count == 44 else { return false }

        // Check if address contains only valid base58 characters
        let base58Charset = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        let addressCharSet = CharacterSet(charactersIn: address)
        let validCharSet = CharacterSet(charactersIn: base58Charset)
        return addressCharSet.isSubset(of: validCharSet)
    }
    
    func onComplete() async throws -> String {
        guard let walletAddress else {
            throw TubError.somethingWentWrong(reason: "Cannot transfer: not logged in")
        }

        if !validateAddress(recipient) {
            throw TubError.somethingWentWrong(reason: "Invalid recipient address")
        }

        let buyAmountUsdc = Int(buyAmountUsd * USDC_DECIMALS)

        do {
            await MainActor.run {
            sending = true
            }
            let txId = try await Network.shared.transferUsdc(
                fromAddress: walletAddress,
                toAddress: recipient,
                amount: buyAmountUsdc
            )
            await MainActor.run {
                sending = false
            }
            return txId
        }

        catch {
            await MainActor.run {
                sending = false
            }
            throw error
        }
    }

}

struct WithdrawView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var notificationHandler: NotificationHandler
    @StateObject private var vm = WithdrawModel()
    @Environment(\.dismiss) private var dismiss

    func handleContinue() {
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
                .onChange(of: vm.buyAmountUsdString) { 
                    let text = vm.buyAmountUsdString
                    
                    // Validate decimal places
                    let components = text.components(separatedBy: ".")
                    if components.count > 1 {
                        let decimals = components[1]
                        if decimals.count > 2 {
                            vm.buyAmountUsdString = String(text.dropLast())
                        }
                    }
                    
                    // Validate if it's a decimal
                    if !text.isEmpty && !text.isDecimal() {
                        vm.buyAmountUsdString = String(text.dropLast())
                    }
                    
                    let amount = text.doubleValue
                    vm.buyAmountUsd = amount  // Update the numeric value
                }
                .font(.sfRounded(size: .xl5, weight: .semibold))
                .foregroundStyle(
                    vm.buyAmountUsd == 0 ||
                    (userModel.balanceUsdc ?? 0) < priceModel.usdToUsdc(usd: vm.buyAmountUsd)
                    ? .tubError
                    : .tubText
                )
                .frame(minWidth: 50)
                .fixedSize()
                Spacer()
            }
            .frame(maxWidth: 300)
            .padding(.horizontal)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Spacer().frame(height: UIScreen.height(Layout.Spacing.md))
                numberInput
                
                Text("Your Balance \(priceModel.formatPrice(usdc: userModel.balanceUsdc ?? 0))")
                    .font(.sfRounded(size: .lg, weight: .medium))
                    .foregroundStyle(.tubBuyPrimary)
                
                Spacer().frame(height: UIScreen.height(Layout.Spacing.lg))
                RecipientSelectView(vm: vm)
                Spacer()
                
                PrimaryButton(
                    text: "Confirm",
                    textColor: .tubTextInverted,
                    backgroundColor: .tubBuyPrimary,
                    disabled: !vm.validateAddress(vm.recipient) ||
                             vm.buyAmountUsd == 0 ||
                             (userModel.balanceUsdc ?? 0) < priceModel.usdToUsdc(usd: vm.buyAmountUsd),
                    loading: vm.sending,
                    action: handleContinue
                )
            }
            .padding(UIScreen.width(Layout.Spacing.md))
            .navigationTitle("Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.tubText)
                            .padding(6)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
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

}

struct RecipientSelectView: View {
    @EnvironmentObject var priceModel: SolPriceModel
    @State var showError: Bool = false
    @ObservedObject var vm: WithdrawModel

    var body: some View {
        VStack(alignment: .leading, spacing: UIScreen.height(Layout.Spacing.xs)) {
            Text("To")
                .font(.sfRounded(size: .lg, weight: .medium))
                .foregroundStyle(.tubBuyPrimary)
            
            VStack(alignment: .leading, spacing: UIScreen.height(Layout.Spacing.tiny)) {
                HStack(spacing: UIScreen.width(Layout.Spacing.xs)) {
                    Image("Solana")
                        .resizable()
                        .frame(width: 32, height: 32, alignment: .center)
                    
                    Text("Solana Wallet")
                        .font(.sfRounded(size: .lg, weight: .medium))
                        .foregroundStyle(.tubText)
                }
                
                HStack {
                    TextField(
                        "",
                        text: $vm.recipient,
                        prompt: Text("Enter Solana address")
                            .foregroundStyle(.tubNeutral)
                    )
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .font(.sfRounded(size: .lg, weight: .regular))
                    
                    Image(systemName: "pencil")
                        .foregroundStyle(.tubNeutral)
                }
                .padding(.vertical, 8)
                
                if showError {
                    Text("Solana Address is invalid")
                        .font(.sfRounded(size: .sm, weight: .regular))
                        .foregroundStyle(.tubError)
                }
            }
        }
        .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
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
    }
}

#Preview {
    @Previewable @StateObject var priceModel = {
        let model = SolPriceModel.shared
        spoofPriceModelData(model)
        return model
    }()

    @Previewable @StateObject var userModel = UserModel.shared

    VStack {
        WithdrawView()
            .environmentObject(userModel)
            .environmentObject(priceModel)
            .preferredColorScheme(.light)
    }
}
