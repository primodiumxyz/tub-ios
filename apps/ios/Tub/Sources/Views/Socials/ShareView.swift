//
//  ShareView.swift
//  Tub
//
//  Created by yixintan on 12/20/24.
//

import SwiftUI
import Photos

struct ShareView: View {
    let tokenName: String
    let tokenSymbol: String
    let tokenImageUrl: String
    let tokenMint: String
    @StateObject private var tokenModel = TokenModel()
    @State private var showingSaveSuccess = false
    @State private var loadedImage: Image?
    @EnvironmentObject private var userModel: UserModel
    
    var shareText: String {
        """
        You've Got to See This. 
        
        I've been trading $\(tokenSymbol) and it's 🚀
        
        Download Tub: https://tub.app
        """
    }
    
    var gainPercentage: Double {
        guard let transactions = userModel.txs else {
            print("DEBUG: No transactions found")
            return 0 
        }
        
        let tokenTxs = transactions.filter { $0.mint == tokenMint }
        
        if let latestBuy = tokenTxs.first(where: { $0.isBuy }),
           let latestSell = tokenTxs.first(where: { !$0.isBuy && $0.date > latestBuy.date }) {
            
            let buyValue = abs(latestBuy.valueUsd) 
            let sellValue = latestSell.valueUsd

            return ((sellValue - buyValue) / buyValue) * 100
        }
        return 0
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
                        Text("\(String(format: "%.2f", gainPercentage))%")
                            .font(.sfRounded(size: .xl2, weight: .bold))
                            .foregroundStyle(gainPercentage >= 0 ? 
                                Color(uiColor: UIColor(named: "tubSuccess")!) :
                                Color(uiColor: UIColor(named: "tubError")!))
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
                    .foregroundStyle(Color(uiColor: UIColor(named: "tubBuyPrimary")!))
                
                Image(uiImage: UIImage(named: "Logo") ?? UIImage())
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.bottom, 24)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .background(Color(uiColor: .systemGray6))
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
                            icon: "square.and.arrow.down",
                            color: .tubSellPrimary,
                            iconSize: 20,
                            horizontalPadding: 16,
                            text: "Save",
                            backgroundColor: .white,
                            strokeColor: .tubSellPrimary,
                            action: saveImage
                        )
                        
                        ShareLink(
                            item: shareText,
                            preview: SharePreview(
                                "Share \(tokenName)",
                                image: Image("Logo")
                            )
                        ) {
                            PillImageLabel(
                                icon: "square.and.arrow.up",
                                color: .white,
                                iconSize: 20,
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
