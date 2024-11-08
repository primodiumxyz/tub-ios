//
//  CoinbaseOnramp.swift
//  Tub
//
//  Created by Henry on 11/5/24.
//

import SwiftUI
import SafariServices

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
                SafariView(url: url)
            }
        }
        .onAppear {
            fetchCoinbaseUrl()
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ safariViewController: SFSafariViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    CoinbaseOnrampView()
}
