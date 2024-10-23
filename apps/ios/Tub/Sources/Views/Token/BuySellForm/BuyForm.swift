//
//  BuyForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct BuyForm: View {
    @Binding var isVisible: Bool
    @ObservedObject var tokenModel: TokenModel
    var onBuy: (Int, ((Bool) -> Void)?) -> ()
    
    @EnvironmentObject private var userModel: UserModel
    @State private var buyAmountString: String = ""
    @State private var buyAmountLamps: Int = 0
    @State private var isValidInput: Bool = true
    
    @State private var dragOffset: CGFloat = 0.0 
    @State private var slideOffset: CGFloat = UIScreen.main.bounds.height
    @State private var animatingSwipe: Bool = false
    @State private var isClosing: Bool = false
    
    func handleBuy() {
        let _ = onBuy(buyAmountLamps, { success in
            if success {
                resetForm()
            }
        })
    }
    
    func updateBuyAmount(_ amount: Int) {
        buyAmountString = PriceFormatter.formatPrice(amount)
        buyAmountLamps = amount
        isValidInput = true
    }
    
    func resetForm() {
        buyAmountString = ""
        buyAmountLamps = 0
        isValidInput = true
        animatingSwipe = false
    }
    
    var body: some View {
        VStack() {
            VStack(spacing: 8) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 60, height: 4)
                    .offset(y: -15)
                
                HStack {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    TextField("", text: $buyAmountString, prompt: Text("0", comment: "placeholder").foregroundColor(.white.opacity(0.3)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .onChange(of: buyAmountString) { newValue in
                            if let amount = Int(buyAmountString), amount >= 0 {
                                buyAmountLamps = amount * Int(1e9)
                                isValidInput = true
                            } else {
                                isValidInput = false
                            }
                        }
                        .font(.sfRounded(size: .xl4, weight: .bold))
                        .foregroundColor(isValidInput ? .white : .red)
                        .frame(width: 150, alignment: .trailing)
                    
                    
                    
                    Text("SOL")
                        .font(.sfRounded(size: .xl2, weight: .bold))
                        .padding(8)
                    
                    Spacer()
                }
                
                // Add token conversion display
                if let currentPrice = tokenModel.prices.last?.price, currentPrice > 0 {
                    let tokenAmount = buyAmountLamps * Int(1e9) / currentPrice // scale up to keep an additional 1e9 precision
                    Text("\(PriceFormatter.formatPrice(tokenAmount)) \(tokenModel.token.symbol)")
                        .font(.sfRounded(size: .base, weight: .bold))
                        .opacity(0.8)
                }
                
                // Add pill-shaped buttons
                HStack(spacing: 8) {
                    ForEach([10, 25, 50, 100], id: \.self) { amount in
                        Button(action: {
                            
                            updateBuyAmount(amount * userModel.balance / 100)
                        }) {
                            Text(amount == 100 ? "MAX" : "\(amount)%")
                                .font(.sfRounded(size: .base, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top, 10)
                
                SwipeToEnterView(text: "Swipe to buy", onUnlock: handleBuy, disabled: buyAmountLamps == 0 || buyAmountString == "")
                    .padding(.top, 10)
            }.background(AppColors.darkBlueGradient)
            .padding()
            .cornerRadius(20)
            .frame(height: 250)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(AppColors.darkBlueGradient)
        .cornerRadius(26)
        .frame(height: 250)
        .offset(y: max(dragOffset, slideOffset))
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
                            isVisible = false // Close the form
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                slideOffset = 150
            }
        }
        .onChange(of: isVisible) { newValue in
            if newValue {
                // Reset when becoming visible
                isClosing = false
                dragOffset = 0
                slideOffset = 150
                resetForm()
            } else if !isClosing {
                // Only animate closing if not already closing from gesture
                withAnimation(.easeInOut(duration: 0.4)) {
                    dragOffset = UIScreen.main.bounds.height
                }
            }
        }
    }
}
