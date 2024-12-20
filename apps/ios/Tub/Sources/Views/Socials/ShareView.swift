//
//  ShareView.swift
//  Tub
//
//  Created by yixintan on 12/20/24.
//

import SwiftUI

struct ShareView: View {
    let tokenName: String
    let tokenSymbol: String
    let price: Double
    let priceChange: Double
    
    var shareText: String {
        """
        Check out \(tokenName) ($\(tokenSymbol)) on Tub!
        
        Current Price: $\(String(format: "%.6f", price))
        24h Change: \(String(format: "%.2f", priceChange))%
        
        Download Tub: https://tub.app
        """
    }
    
    var body: some View {
        NavigationStack {
            ShareLink(
                item: shareText,
                preview: SharePreview(
                    "Share \(tokenName)",
                    image: Image("Logo")
                )
            ) {
                PillImageButton(
                    icon: "square.and.arrow.up",
                    color: .white,
                    iconSize: 20,
                    text: "Share",
                    backgroundColor: .tubSellPrimary
                )
            }
        }
    }
}

#Preview {
    ShareView(
        tokenName: "Sample Token",
        tokenSymbol: "TOK",
        price: 0.123456,
        priceChange: 5.43
    )
}
