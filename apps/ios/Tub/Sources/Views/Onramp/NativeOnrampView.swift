//
//  NativeOnrampView.swift
//  Tub
//
//  Created by Henry on 1/21/25.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct NativeOnrampView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @State private var qrCode : UIImage? = nil
    
    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        guard let outputImage = filter.outputImage else { return UIImage() }
        
        // Scale up the QR code
        let scale = CGAffineTransform(scaleX: 10.0, y: 10.0)
        let scaledImage = outputImage.transformed(by: scale)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return UIImage()
        }
        
        let qrImage = UIImage(cgImage: cgImage)
        let size = qrImage.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        qrImage.draw(in: CGRect(origin: .zero, size: size))
        
        // Add App Icon
        if let appIcon = UIImage(named: "Logo") {
            appIcon.draw(
                in: CGRect(
                    x: size.width * 0.4,
                    y: size.height * 0.4,
                    width: size.width * 0.2,
                    height: size.height * 0.2
                ))
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage ?? UIImage()
    }
    var body: some View {
        VStack {
            Text("Send from Wallet").foregroundStyle(.tubText).opacity(0.5).padding(.top, 36)
            if let address = userModel.walletAddress, let qrCode {
                VStack(spacing: UIScreen.height(Layout.Spacing.md)) {
                    Spacer()
                    
                    // Balance
                    VStack {
                        HStack {
                            Text("Your Balance ")
                                .font(.sfRounded(size: .lg, weight: .medium))
                                .foregroundStyle(.tubText)
                            Text(priceModel.formatPrice(usdc: userModel.usdcBalance ?? 0))
                                .foregroundStyle(.tubBuyPrimary)
                                .font(.sfRounded(size: .lg, weight: .medium))
                        }
                        
                        // QR Code
                        Image(uiImage: qrCode)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    
                    // Wallet Address
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "wallet.bifold")
                                Text("Solana Wallet")
                            }
                            .font(.sfRounded(size: .base))
                            .foregroundStyle(.tubNeutral)
                            
                            // USDC Note
                            Text("Note: only send USDC.")
                                .font(.sfRounded(size: .sm))
                                .foregroundStyle(.tubWarning)
                        }
                        .padding(.horizontal, 8)
                        
                        HStack {
                            Text(address)
                                .font(.sfRounded(size: .sm))
                                .foregroundStyle(.tubText)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Button(action: {
                                UIPasteboard.general.string = address
                                notificationHandler.show("Address copied to clipboard!", type: .success)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundStyle(.tubBuyPrimary)
                            }
                        }
                        .padding(.horizontal, UIScreen.width(Layout.Spacing.sm))
                        .padding(.vertical, 8)
                        .background(Color.tubAltSecondary.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                
                
            } else {
                VStack(spacing: UIScreen.height(Layout.Spacing.md)) {
                    Spacer()
                    
                    Text("Login to continue")
                        .font(.sfRounded(size: .xl, weight: .medium))
                        .foregroundStyle(.tubText)
                    
                    Spacer()
                }
            }
        }
                .padding(UIScreen.width(Layout.Spacing.md))

        .onAppear {
            guard let address = userModel.walletAddress else {
                self.qrCode = nil
                return
            }
            self.qrCode = generateQRCode(from: address)
            
        }  .onChange(of: userModel.walletAddress) {
            _, address in
            guard let address else {
                self.qrCode = nil
                return
            }
            
            self.qrCode = generateQRCode(from: address)
        }
    }
}

#Preview {
    NativeOnrampView()
        .environmentObject(UserModel.shared)
        .environmentObject(SolPriceModel.shared)
        .environmentObject(NotificationHandler())
}
