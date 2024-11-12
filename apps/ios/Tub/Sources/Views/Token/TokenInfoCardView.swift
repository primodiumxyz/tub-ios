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
    @Binding var activeTab: String
    @EnvironmentObject var priceModel: SolPriceModel
    
    @State private var dragOffset: CGFloat = 0.0
    @State private var animatingSwipe: Bool = false
    @State private var isClosing: Bool = false
    
    private struct StatValue {
        let text: String
        let color: Color?
    }
    
    private var stats: [(String, StatValue)] {
        var stats = [(String, StatValue)]()
        
        if let purchaseData = tokenModel.purchaseData, activeTab == "sell" {
            // Calculate current value in lamports
            let currentValueLamps = Int(Double(tokenModel.balanceLamps) / 1e9 * Double(tokenModel.prices.last?.price ?? 0))
            
            // Calculate profit
            let initialValueUsd = priceModel.lamportsToUsd(lamports: purchaseData.price)
            let currentValueUsd = priceModel.lamportsToUsd(lamports: currentValueLamps)
            let gains = currentValueUsd - initialValueUsd
            

            if purchaseData.amount > 0 {
                let percentageGain = gains / initialValueUsd * 100
                stats += [
                    ("Gains", StatValue(
                        text: "\(priceModel.formatPrice(usd: gains, showSign: true)) (\(String(format: "%.2f", percentageGain))%)",
                        color: gains >= 0 ? AppColors.green : AppColors.red
                    ))
                ]
            }
            // Add position stats
            stats += [
                ("You Own", StatValue(
                    text: "\(priceModel.formatPrice(lamports: currentValueLamps, maxDecimals: 2, minDecimals: 2)) (\(priceModel.formatPrice(lamports: tokenModel.balanceLamps, showUnit: false)) \(tokenModel.token.symbol))",
                    color: nil
                ))
            ]
            
        }
        
        // Add original stats from tokenModel
        stats += tokenModel.getTokenStats(priceModel: priceModel).map { 
            ($0.0, StatValue(text: $0.1, color: nil))
        }
        
        return stats
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
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Stats")
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.bottom,4)
                    
                    
                    ForEach(stats, id: \.0) { stat in
                        VStack(spacing:10) {
                            HStack(alignment: .center)  {
                                Text(stat.0)
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundColor(AppColors.gray)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Text(stat.1.text)
                                    .font(.sfRounded(size: .base, weight: .semibold))
                                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                                    .foregroundColor(stat.1.color ?? AppColors.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            //divider
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 0.5)
                                .background(AppColors.gray.opacity(0.5))
                        }
                        .padding(.vertical, 6)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("About")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        
                        Text("\(tokenModel.token.description)")
                            .font(.sfRounded(size: .sm, weight: .regular))
                            .foregroundColor(AppColors.lightGray)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(alignment: .center, spacing: 4) {
                        Image("X-logo-white")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(" @ \(tokenModel.token.symbol)")
                            .font(.sfRounded(size: .lg, weight: .semibold))
                            .foregroundColor(AppColors.aquaGreen)
                    }
                    .padding(.top, 8.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                }
                .padding(.horizontal,20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(AppColors.darkGrayGradient)
                .cornerRadius(20)
            }
        }
        .padding(.vertical, 0)
        .padding(.horizontal,20)
        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.44, alignment: .topLeading)
        .background(AppColors.black)
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
