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
    @State private var amountString: String = ""
    @State private var amount: Double = 100.0  // Default amount
    @State private var isValidInput: Bool = true
    @State private var showInput: Bool = true
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        Group {
            if showInput {
                VStack(spacing: 20) {
                    numberInput
                    continueButton
                }
                .padding()
            }
            else if let url = url {
                WebView(url: url)
            }
            else {
                LoadingView(identifier: "Coinbase onramp")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            isAmountFocused = true
        }
    }

    private var numberInput: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Spacer()
                Text("$")
                    .font(.sfRounded(size: .xl4, weight: .bold))
                    .foregroundColor(Color.white)

                TextField("", text: $amountString, prompt: Text("100").foregroundColor(Color.white.opacity(0.3)))
                    .focused($isAmountFocused)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification)) {
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
                    .foregroundColor(isValidInput ? Color.white : Color.red)
                    .frame(minWidth: 50)
                    .fixedSize()
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    private var continueButton: some View {
        Button(action: {
            guard let walletAddress = userModel.walletAddress else { return }
            let urlStr =
                "https://pay.coinbase.com/buy?appId=70955045-7672-4640-b524-0a5aff9e074e&addresses={\"\(walletAddress)\":[\"solana\"]}&assets=[\"USDC\"]&presetFiatAmount=\(amount)"
            url = URL(string: urlStr)
            showInput = false
        }) {
            HStack(alignment: .firstTextBaseline) {
                Text("Deposit with ")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .padding(.trailing, -4)
                Image("Coinbase")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 16)
            }
            .foregroundColor(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("purple"))
            .cornerRadius(26)
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        // Add user script to force dark mode
        let darkScript = """
                document.documentElement.style.colorScheme = 'dark';
                document.body.style.backgroundColor = 'black';
                document.body.style.color = 'white';
                document.querySelector('.cds-button-b17kdj8k').style.background = '#6E00FF';

            """
        let script = WKUserScript(source: darkScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: configuration)

        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .black

        // Force dark mode at the WebView level
        if #available(iOS 13.0, *) {
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
