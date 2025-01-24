//
//  ShareView.swift
//  Tub
//
//  Created by yixintan on 12/20/24.
//

import SwiftUI
import Photos

struct GainMetrics {
    let usd: Double
    let percentage: Double
}

struct ShareView: View {
    let tokenName: String
    let tokenSymbol: String
    let tokenImageUrl: String
    let tokenMint: String
    @StateObject private var tokenModel = TokenModel()
    @State private var showingSaveSuccess = false
    @State private var loadedImage: Image?
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel

    
    var shareText: String {
        """
        I've been trading $\(tokenSymbol) and it's 🚀
        
        Download Tub: https://tub.app
        """
    }
    
    private var shareItem: ShareItem {
        let renderer = ImageRenderer(content: shareCardView)
        renderer.scale = UIScreen.main.scale
        
        return ShareItem(
            image: Image(uiImage: renderer.uiImage ?? UIImage(named: "Logo")!),
            caption: shareText
        )
    }
    
    var gains: GainMetrics {
        guard let transactions = userModel.txs else {
            print("DEBUG: No transactions found")
            return GainMetrics(usd: 0, percentage: 0)
        }
        
        let tokenTxs = transactions.filter { $0.mint == tokenMint }
        
        // Find the most recent sell
        guard let latestSell = tokenTxs.first(where: { !$0.isBuy }) else {
            return GainMetrics(usd: 0, percentage: 0)
        }
        
        // Find the most recent buy that occurred before this sell
        let previousTxs = tokenTxs.filter { $0.date < latestSell.date }
        let validBuy = previousTxs.first { buyTx in
            guard buyTx.isBuy else { return false }
            // Check if there are any sells between this buy and our latest sell
            let txsBetween = tokenTxs.filter { tx in 
                tx.date > buyTx.date && tx.date < latestSell.date && !tx.isBuy
            }
            return txsBetween.isEmpty
        }
        
        guard let latestBuy = validBuy else {
            return GainMetrics(usd: 0, percentage: 0)
        }
        
        let buyValue = abs(latestBuy.valueUsd) 
        let sellValue = latestSell.valueUsd

        return GainMetrics(usd: sellValue - buyValue, percentage: ((sellValue - buyValue) / buyValue) * 100)
    }
    
    private func saveImage() {
        let renderer = ImageRenderer(content: shareCardView)
        renderer.scale = UIScreen.main.scale
        
        // Ensure we get a valid UIImage
        guard let uiImage = renderer.uiImage else {
            print("Failed to render image")
            return
        }
        
        guard let imageData = uiImage.pngData(),
              let compatibleImage = UIImage(data: imageData) else {
            print("Failed to convert image format")
            return
        }
        
        // Save to photo library
        UIImageWriteToSavedPhotosAlbum(compatibleImage, nil, nil, nil)
        showingSaveSuccess = true
        
        // Hide success message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSaveSuccess = false
        }
    }
    
    private var shareCardView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if let loadedImage = loadedImage {
                    loadedImage
                        .resizable()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    AsyncImage(url: URL(string: tokenImageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            let _ = DispatchQueue.main.async {
                                loadedImage = image
                            }
                            image
                                .resizable()
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        default:
                            Color.gray
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4){
                    Text("$\(tokenSymbol)")
                        .font(.sfRounded(size: .xl3, weight: .bold))
                        .foregroundStyle(Color(uiColor: UIColor(named: "tubNeutral")!))
                                        
                    if tokenModel.isReady {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(priceModel.formatPrice(usd: gains.usd))")
                                .font(.sfRounded(size: .xl2, weight: .bold))
                                .foregroundStyle(gains.usd >= 0 ?
                                    Color(uiColor: UIColor(named: "tubSuccess")!) :
                                    Color(uiColor: UIColor(named: "tubError")!))

                            Text("\(String(format: "%.2f", gains.percentage))%")
                                .font(.sfRounded(size: .sm, weight: .bold))
                                .foregroundStyle(gains.usd >= 0 ?
                                    Color(uiColor: UIColor(named: "tubSuccess")!) :
                                    Color(uiColor: UIColor(named: "tubError")!))
                        }
                    }
                }
                .padding(.leading, 16)

            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .padding(.bottom, 16)
            
            
            // Tub icon
            HStack {
                Text("@tub")
                    .font(.sfRounded(size: .base, weight: .medium))
                    .foregroundStyle(Color(uiColor: .tubAccent))
                
                Image(uiImage: UIImage(named: "Logo") ?? UIImage())
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.bottom, 24)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .background(Color(uiColor: .tubTextInverted))
        .cornerRadius(16)
        .frame(width: 300)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with bubbles
                Color(UIColor.systemBackground)
                    .backgroundBubbleEffect()
                    .ignoresSafeArea()
                
                // Content
                VStack(spacing: 8) {
                    Text("Share Your Wins")
                        .font(.sfRounded(size: .xl2, weight: .bold))
                        .foregroundStyle(.tubBuyPrimary)
                    
                    shareCardView
                        .padding(.top, 24)
                        .padding(.bottom, -30)
                    
                    HStack {
                        PillImageButton(
                            icon: "Save_NObubble",
                            isSystemIcon: false,
                            color: .tubSellPrimary,
                            iconSize: 36,
                            horizontalPadding: 16,
                            text: "Save",
                            backgroundColor: .white,
                            strokeColor: .tubSellPrimary,
                            action: saveImage
                        )
                        
                        ShareLink(
                            item: shareItem,
                            message: Text(shareItem.caption),
                            preview: SharePreview(
                                Text("Share \(tokenName)"),
                                image: shareItem.image
                            )
                        ) {
                            PillImageLabel(
                                icon: "Share_NObubble",
                                isSystemIcon: false,
                                color: .white,
                                iconSize: 36,
                                horizontalPadding: 32,
                                text: "Share",
                                backgroundColor: .tubSellPrimary
                            )
                        }
                    }
                    .overlay {
                        if showingSaveSuccess {
                            Text("Image saved!")
                                .font(.sfRounded(size: .base, weight: .medium))
                                .foregroundStyle(.tubTextInverted)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.primary)
                                .cornerRadius(8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.easeInOut, value: showingSaveSuccess)
                                .zIndex(1)
                        }
                    }
                }
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            tokenModel.initialize(with: tokenMint)
        }
    }
}

#Preview {
    ShareView(
        tokenName: "Sample Token",
        tokenSymbol: "TOK",
        tokenImageUrl: "https://example.com/token-image.png",
        tokenMint: "sample_mint"
    )
}
