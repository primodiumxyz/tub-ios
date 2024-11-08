//
//  CoinbaseOnramp.swift
//  Tub
//
//  Created by Henry on 11/5/24.
//

import SwiftUI
import WebKit

struct CoinbaseOnrampView: View {
    @State private var url: URL?
    @State private var isLoading = true
    @State private var error: String?
    
    func fetchCoinbaseUrl() {
        Network.shared.getCoinbaseSolanaOnrampUrl { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if let url = URL(string: response.url) {
                        self.url = url
                    } else {
                        self.error = "Invalid URL received"
                    }
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if let url = url {
                WebView(url: url)
            }
        }
        .onAppear {
            fetchCoinbaseUrl()
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

#Preview {
    CoinbaseOnrampView()
}
