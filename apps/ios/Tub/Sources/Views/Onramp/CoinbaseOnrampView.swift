//
//  CoinbaseOnramp.swift
//  Tub
//
//  Created by Henry on 11/5/24.
//

import SwiftUI
import SafariServices

struct CoinbaseOnrampView: View {
    @State private var url = URL(string: 
        "https://pay.coinbase.com/buy?appId=70955045-7672-4640-b524-0a5aff9e074e&addresses={\"2KNF35JnG97K3oeeEY8BJv4SMfqMQhrZASbD58QQP8f7\":[\"solana\"]}&assets=[\"USDC\"]&presetFiatAmount=10"
    )!

    
    var body: some View {
        Group {
                SafariView(url: url)
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
