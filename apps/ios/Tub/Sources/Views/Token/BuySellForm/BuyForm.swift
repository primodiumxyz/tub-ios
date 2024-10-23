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
    @State private var buyAmountUSDString: String = ""
    @State private var buyAmountUSD : Double = 0
    @State private var isValidInput: Bool = true
    
    @State private var dragOffset: CGFloat = 0.0
    @State private var slideOffset: CGFloat = UIScreen.main.bounds.height
    @State private var animatingSwipe: Bool = false
    @State private var isClosing: Bool = false
    
    func handleBuy() {
        let buyAmountLamps = PriceFormatter.usdToLamports(usd: buyAmountUSD)
        let _ = onBuy(buyAmountLamps, { success in
            if success {
                resetForm()
            }
        })
    }
    
    func updateBuyAmount(_ amountUSD: Double) {
        if amountUSD == 0 {
            isValidInput = false
            return
        }
        
        buyAmountUSDString = PriceFormatter.formatPrice(usd: amountUSD)
        buyAmountUSD = amountUSD
        isValidInput = true
    }
    
    func resetForm() {
        buyAmountUSDString = ""
        buyAmountUSD = 0
        isValidInput = true
        animatingSwipe = false
    }
    
    
    
    var body: some View {
        VStack {
            formContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(AppColors.darkBlueGradient)
        .cornerRadius(26)
        .frame(height: 250)
        .offset(y: max(dragOffset, slideOffset))
        .gesture(dragGesture)
        .onAppear(perform: animateAppearance)
        .onChange(of: isVisible, perform: handleVisibilityChange)
    }
    
    private var formContent: some View {
        VStack(spacing: 8) {
            dragIndicator
            numberInput
            tokenConversionDisplay
            amountButtons
            SwipeToEnterView(text: "Swipe to buy", onUnlock: handleBuy, disabled: buyAmountUSD == 0)
                .padding(.top, 10)
        }
        .background(AppColors.darkBlueGradient)
        .padding()
        .cornerRadius(20)
        .frame(height: 250)
    }
    
    private var numberInput: some View {
        HStack {
            Spacer()
            Text("$")
                .font(.sfRounded(size: .xl2, weight: .bold))
                .padding(8)
            

            
            TextField("", text: $buyAmountUSDString, prompt: Text("0", comment: "placeholder").foregroundColor(.white.opacity(0.3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .onChange(of: buyAmountUSDString) { newValue in
                    let filtered = newValue.filter { "0123456789.".contains($0) }
                    
                    // Limit to two decimal places
                    let components = filtered.components(separatedBy: ".")
                    if components.count > 1 {
                        let wholeNumber = components[0]
                        let decimal = String(components[1].prefix(2))
                        buyAmountUSDString = "\(wholeNumber).\(decimal)"
                    } else {
                        buyAmountUSDString = filtered
                    }
                    
                    if let amount = Double(buyAmountUSDString) {
                        buyAmountUSD = amount
                        isValidInput = true
                    } else {
                        buyAmountUSD = 0
                        isValidInput = false
                    }
                }
                .font(.sfRounded(size: .xl4, weight: .bold))
                .foregroundColor(isValidInput ? .white : .red)
                .frame(width: 150, alignment: .trailing)
            
            Spacer()
            Spacer()
            Spacer()
        }
    }
    private var dragIndicator: some View {
        Capsule()
            .fill(Color.white.opacity(0.3))
            .frame(width: 60, height: 4)
            .offset(y: -15)
    }
    
    private var tokenConversionDisplay: some View {
        Group {
            if let currentPrice = tokenModel.prices.last?.price {
                let buyAmountLamps = PriceFormatter.usdToLamports(usd: buyAmountUSD)
                let tokenAmount = Int(Double(buyAmountLamps) / Double(currentPrice) * 1e9)

                Text("\(PriceFormatter.formatPrice(lamports: tokenAmount, showUnit: false)) \(tokenModel.token.symbol)")
                    .font(.sfRounded(size: .base, weight: .bold))
                    .opacity(0.8)
            }
        }
    }
    
    private var amountButtons: some View {
        HStack(spacing: 8) {
            ForEach([10, 25, 50, 100], id: \.self) { amount in
                amountButton(for: amount)
            }
        }
        .padding(.top, 10)
    }
    
    private func amountButton(for amount: Double ) -> some View {
        Button(action: {
            updateBuyAmount(amount)
        }) {
            Text(amount == 100 ? "MAX" : "\(amount, specifier: "%.0f")%")
                .font(.sfRounded(size: .base, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                handleDragGestureEnd(value)
            }
    }
    
    private func handleDragGestureEnd(_ value: DragGesture.Value) {
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
    
    private func animateAppearance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
            slideOffset = 150
        }
    }
    
    private func handleVisibilityChange(_ newValue: Bool) {
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
