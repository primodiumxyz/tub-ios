//
//  CoinbaseOnramp.swift
//  Tub
//
//  Created by Henry on 11/5/24.
//

import SwiftUI
import WebKit

struct CoinbaseOnrampView: View {
    @State private var url: URL? = nil
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    @State private var amountString: String = ""
    @State private var amount: Double = 100.0  // Default amount
    @State private var isValidInput: Bool = true
    @State private var showInput: Bool = true
    @FocusState private var isAmountFocused: Bool
    @State private var showWebView: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack{
            VStack {
                if showInput {
                    VStack(alignment: .center) {
                        Spacer().frame(height: UIScreen.height(Layout.Spacing.md))

                        numberInput
                        
                        Text("Your Balance \(priceModel.formatPrice(usdc: userModel.balanceUsdc ?? 0))")
                            .font(.sfRounded(size: .lg, weight: .medium))
                            .foregroundStyle(.tubBuyPrimary)
                        
                        Spacer()
                        
                        if amountString.isEmpty {
                            amountButtons
                        } else {
                            continueButton
                        }
                        
                        if userModel.walletAddress == nil {
                            Text("Connect a wallet to continue").font(.sfRounded()).foregroundStyle(.tubError)
                        }
                    }
                }
                else {
                    LoadingView(identifier: "Coinbase onramp")
                }
                
            }
            .padding(UIScreen.width(Layout.Spacing.md))
            .navigationTitle("Deposit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.tubBuyPrimary)
                            .padding(8)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .onAppear {
                isAmountFocused = true
            }
            .sheet(isPresented: $showWebView) {
                if let url = url {
                    ZStack(alignment: .top) {
                        HStack(alignment: .center, spacing: 0) {
                            Rectangle()
                                .foregroundStyle(.clear)
                                .frame(width: 60, height: 3)
                                .background(.tubNeutral)
                                .cornerRadius(100)
                        }
                        .padding()
                        .zIndex(2)
                        
                        WebView(url: url)
                            .ignoresSafeArea()
                    }
                }
            }
        }
    }

    private var numberInput: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Spacer()
                Text("$")
                    .font(.sfRounded(size: .xl4, weight: .bold))

                TextField("", text: $amountString, prompt: Text("100.00").foregroundStyle(.tubNeutral))
                    .focused($isAmountFocused)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onReceive(
                        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification)
                    ) {
                        obj in
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

                            if !text.isEmpty && !text.isDecimal() {
                                textField.text = String(text.dropLast())
                            }

                            let inputAmount = text.doubleValue
                            if inputAmount > 0 {
                                amount = inputAmount
                                amountString = text
                            }
                            isValidInput = true
                        }
                    }
                    .font(.sfRounded(size: .xl5, weight: .bold))
                    .foregroundStyle(isValidInput ? .tubText : .tubError)
                    .frame(minWidth: 50)
                    .fixedSize()
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    private var continueButton: some View {
        ContentButton(
            backgroundColor: .tubBuyPrimary,
            disabled: userModel.walletAddress == nil || amountString == "" || !isValidInput,
            action: {
                isAmountFocused = false
                
                guard let walletAddress = userModel.walletAddress else { return }
                let urlStr =
                    "https://pay.coinbase.com/buy?appId=70955045-7672-4640-b524-0a5aff9e074e&addresses={\"\(walletAddress)\":[\"solana\"]}&assets=[\"USDC\"]&presetFiatAmount=\(amount)"
                print(urlStr)
                url = URL(string: urlStr)
                showWebView = true
            }
        ) {
            HStack(alignment: .firstTextBaseline) {
                Text("Deposit with")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .foregroundStyle(.tubTextInverted)
                    .padding(.trailing, -4)
                Image("Coinbase")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 16)
            }
        }
    }
    
    let amounts: [Int] = [50, 100, 200, 1000]
    private var amountButtons: some View {
        HStack(spacing: 10) {
            ForEach(amounts, id: \.self) { amount in
                CapsuleButton(
                    text: "$\(amount)",
                    textColor: .tubBuyPrimary,
                    backgroundColor: .clear,
                    borderColor: .tubAltSecondary,
                    borderWidth: 1,
                    action: {
                        amountString = String(format: "%.2f", Double(amount))
                    }
                )
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)

        webView.backgroundColor = UIColor.systemBackground
        webView.isOpaque = false
        webView.scrollView.backgroundColor = UIColor.systemBackground

        // Force dark mode at the WebView level
        if #available(iOS 13.0, *), colorScheme == .dark {
            webView.overrideUserInterfaceStyle = .dark
        }

        webView.scrollView.bounces = false
        webView.scrollView.showsHorizontalScrollIndicator = false

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

#Preview {
    CoinbaseOnrampView()
        .environmentObject(UserModel.shared)
        .environmentObject(SolPriceModel.shared)
        .preferredColorScheme(.light)
}
