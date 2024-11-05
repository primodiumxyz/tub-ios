//
//  BuyForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct BuyForm: View {
    @Binding var isVisible: Bool
    @Binding var defaultAmount: Double
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var tokenModel: TokenModel
    var onBuy: (Double) -> Void
    
    @EnvironmentObject private var userModel: UserModel
    @State private var buyAmountUsdString: String = ""
    @State private var buyAmountUsd : Double = 0
    @State private var isValidInput: Bool = true
    
    @State private var dragOffset: CGFloat = 0.0
    @State private var slideOffset: CGFloat = UIScreen.main.bounds.height
    @State private var animatingSwipe: Bool = false
    @State private var isClosing: Bool = false
    
    @State private var isKeyboardActive: Bool = false
    @State private var keyboardHeight: CGFloat = 0.0
    private let keyboardAdjustment: CGFloat = 220
    
    @State private var isDefaultOn: Bool = true //by default is on
    
    private func handleBuy() {
        if isDefaultOn {
            defaultAmount = buyAmountUsd
        }
        onBuy(buyAmountUsd)
    }
    
    func updateBuyAmount(_ amountLamps: Int) {
        if amountLamps == 0 {
            isValidInput = false
            return
        }
        
        buyAmountUsdString = priceModel.formatPrice(lamports: amountLamps, showSign: false, showUnit: false, formatLarge: false)
        buyAmountUsd = priceModel.lamportsToUsd(lamports: amountLamps)
        print(amountLamps, buyAmountUsd)
        isValidInput = true
    }
    
    func resetForm() {
        buyAmountUsdString = ""
        buyAmountUsd = 0
        isValidInput = true
        animatingSwipe = false
        isDefaultOn = true
    }
    
    
    
    var body: some View {
        VStack {
            formContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(AppColors.darkGreenGradient)
        .cornerRadius(26)
        .frame(height: 250)
        .offset(y: max(dragOffset, slideOffset - keyboardHeight + (isKeyboardActive ? keyboardAdjustment : 0)))
        .gesture(dragGesture)
        .onAppear(perform: animateAppearance)
        .onChange(of: isVisible, perform: handleVisibilityChange)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardActive = false
        }
    }
    
    private var formContent: some View {
        VStack {
            defaultToggle
            VStack(alignment: .center, spacing: 20) {
                numberInput
//                tokenConversionDisplay
                amountButtons
                buyButton
            }
        }
        .padding(8)
        .frame(height: 230)
    }
    
    private var buyButton: some View {
        Button(action: {
            handleBuy()
        }) {
            HStack {
                Text("Buy")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .foregroundColor(AppColors.aquaGreen)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .inset(by: 0.5)
                    .stroke(AppColors.aquaGreen, lineWidth: 1)
            )
        }
    }
    
    private var numberInput: some View {
        HStack(spacing: 0) {
            Text("$")
                .font(.sfRounded(size: .xl4, weight: .bold))
                .foregroundColor(AppColors.white)
            
            TextField("", text: $buyAmountUsdString, prompt: Text("100", comment: "placeholder").foregroundColor(AppColors.white.opacity(0.3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .onChange(of: buyAmountUsdString) { newValue in
                    if let amount = formatter.number(from:newValue)?.doubleValue {
                        buyAmountUsd = amount
                        buyAmountUsdString = priceModel.formatPrice(usd: amount, showSign: false, showUnit: false, formatLarge: false)
                        isValidInput = true
                    } else {
                        buyAmountUsd = 0
                        isValidInput = false
                    }
                }
                .font(.sfRounded(size: .xl5, weight: .bold))
                .foregroundColor(isValidInput ? .white : .red)
                .frame(width: 150)
                .onTapGesture {
                    isKeyboardActive = true
                    print("Keyboard Activated")
                }
        }
    }
    
    private var defaultToggle: some View {
        HStack {
            Spacer()
            Button(action: {
                isDefaultOn.toggle()
            }) {
                HStack(spacing: 4) {
                    Text("Default")
                        .font(.sfRounded(size: .base, weight: .regular))
                        .foregroundColor(isDefaultOn ? AppColors.white : AppColors.gray)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(isDefaultOn ? AppColors.green : AppColors.gray)
                }
            }
        }
    }
    
    private var tokenConversionDisplay: some View {
        Group {
            if let currentPrice = tokenModel.prices.last?.price {
                let buyAmountLamps = priceModel.usdToLamports(usd: buyAmountUsd)
                let tokenAmount = Int(Double(buyAmountLamps) / Double(currentPrice) * 1e9)

                Text("\(priceModel.formatPrice(lamports: tokenAmount, showUnit: false)) \(tokenModel.token.symbol ?? "")")
                    .font(.sfRounded(size: .base, weight: .bold))
                    .opacity(0.8)
            }
        }
        .onAppear{
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
                isKeyboardActive = true
                print("Keyboard Activated")
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0 // Reset keyboard height
                isKeyboardActive = false
                print("Keyboard Deactivated")
            }
        }
        
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
    
    private var amountButtons: some View {
        HStack(spacing: 10) {
            ForEach([10, 25, 50, 100], id: \.self) { amount in
                amountButton(for: amount)
            }
        }
    }
    
    private func amountButton(for pct: Int) -> some View {
        Button(action: {
            updateBuyAmount(userModel.balanceLamps * pct / 100)
        }) {
            Text(pct == 100 ? "MAX" : "\(pct)%")
                .font(.sfRounded(size: .base, weight: .bold))
                .foregroundColor(AppColors.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(AppColors.white.opacity(0.15))
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
