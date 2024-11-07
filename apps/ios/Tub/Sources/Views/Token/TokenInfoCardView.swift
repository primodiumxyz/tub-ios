//
//  TokenInfoCardView.swift
//  Tub
//
//  Created by yixintan on 10/11/24.
//
import SwiftUI

struct TokenInfoCardView: View {
    @ObservedObject var tokenModel: TokenModel
    @Binding var isVisible: Bool
    @EnvironmentObject var priceModel: SolPriceModel
    
    @State private var dragOffset: CGFloat = 0.0
    @State private var animatingSwipe: Bool = false
    @State private var isClosing: Bool = false
    
    private var stats: [(String, String)] {
        [
            ("Market Cap", priceModel.formatPrice(lamports: (tokenModel.prices.last?.price ?? 0) * (tokenModel.token.supply ?? 0) / Int(pow(10.0, Double(tokenModel.token.decimals ?? 0))))),
            ("Volume (\(String(tokenModel.token.volume?.interval ?? "30s")))", formatLargeNumber(Double(tokenModel.token.volume?.value ?? 0) / 1e9)), // TODO: fix volume calculation
            ("Holders", "53.3K"), // TODO: Add holders data?
            ("Supply", formatLargeNumber(Double(tokenModel.token.supply ?? 0) / pow(10.0, Double(tokenModel.token.decimals ?? 0))))
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Rectangle()
                .foregroundColor(.clear)
                .frame(width: 60, height: 3)
                .background(AppColors.lightGray)
                .cornerRadius(100)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .center)
            
            VStack(alignment: .leading, spacing: 0) {
                
                Text("Stats")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .foregroundColor(AppColors.white)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                
                // grid
                ForEach(0..<stats.count/2, id: \.self) { index in
                    HStack(alignment: .top, spacing: 20) {
                        ForEach(0..<2) { subIndex in
                            let stat = stats[index * 2 + subIndex]
                            VStack {
                                HStack(alignment: .center)  {
                                    Text(stat.0)
                                        .font(.sfRounded(size: .sm, weight: .regular))
                                        .foregroundColor(AppColors.gray)
                                        .fixedSize(horizontal: true, vertical: false)
                                    
                                    Text(stat.1)
                                        .font(.sfRounded(size: .base, weight: .semibold))
                                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                                        .foregroundColor(AppColors.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                //divider
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(height: 0.5)
                                    .background(AppColors.gray.opacity(0.5))
                            }
                        }
                    }
                    .padding(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    Text("\(tokenModel.token.description ?? "")")
                        .font(.sfRounded(size: .sm, weight: .regular))
                        .foregroundColor(AppColors.lightGray)
                        .padding(.horizontal, 8)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .center, spacing: 4) {
                    Image("X-logo-white")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(" @ MONKAY")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                        .foregroundColor(AppColors.aquaGreen)
                }
                .padding(.top, 8.0)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(AppColors.darkGrayGradient)
            .cornerRadius(12)

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.42, alignment: .topLeading)
        .background(AppColors.black)
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 0.5)
                .stroke(AppColors.shadowGray, lineWidth: 1)
        )
        .transition(.move(edge: .bottom))
        .offset(y: dragOffset)
        .ignoresSafeArea(edges: .horizontal)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    let verticalAmount = value.translation.height
                    
                    if verticalAmount > threshold && !animatingSwipe {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            dragOffset = UIScreen.main.bounds.height
                        }
                        animatingSwipe = true
                        isClosing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            isVisible = false // Close the card
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onChange(of: isVisible) { newValue in
            if newValue {
                // Reset when becoming visible
                isClosing = false
                dragOffset = 0
                animatingSwipe = false
            } else if !isClosing {
                // Only animate closing if not already closing from gesture
                withAnimation(.easeInOut(duration: 0.4)) {
                    dragOffset = UIScreen.main.bounds.height
                }
            }
        }
        .transition(.move(edge: .bottom))
    }
}

#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    @Previewable @State var isVisible = true
    @Previewable @StateObject var priceModel = SolPriceModel(mock: true)
    
    TokenInfoCardView(
        tokenModel: TokenModel(walletAddress: "", tokenId: mockTokenId),
        isVisible: $isVisible
    )
    .environmentObject(priceModel)
}
