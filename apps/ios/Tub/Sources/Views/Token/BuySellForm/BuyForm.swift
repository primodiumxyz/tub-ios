//
//  BuyForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct BuyForm: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var priceModel: SolPriceModel
    @ObservedObject var tokenModel: TokenModel
    var onBuy: (Int, ((Bool) -> Void)?) -> ()
    
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
    
    
    func handleBuy() {
        let buyAmountLamps = priceModel.usdToLamports(usd: buyAmountUsd)
        let _ = onBuy(buyAmountLamps, { success in
            if success {
                resetForm()
            }
        })
    }
    
    func updateBuyAmount(_ amountLamps: Int) {
        if amountLamps == 0 {
            isValidInput = false
            return
        }
        
        buyAmountUsdString = priceModel.formatPrice(lamports: amountLamps, showSign: false, showUnit: false)
        buyAmountUsd = priceModel.lamportsToUsd(lamports: amountLamps)
        isValidInput = true
    }
    
    func resetForm() {
        buyAmountUsdString = ""
        buyAmountUsd = 0
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
        .offset(y: max(dragOffset, slideOffset - keyboardHeight + (isKeyboardActive ? keyboardAdjustment : 0)))
        .gesture(dragGesture)
        .onAppear(perform: animateAppearance)
        .onChange(of: isVisible, perform: handleVisibilityChange)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardActive = false
        }
    }
    
    private var formContent: some View {
        VStack(spacing: 8) {
            dragIndicator
            numberInput
            tokenConversionDisplay
            amountButtons
            SwipeToEnterView(text: "Swipe to buy", onUnlock: handleBuy, disabled: buyAmountUsd == 0)
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
            

            
            TextField("", text: $buyAmountUsdString, prompt: Text("0", comment: "placeholder").foregroundColor(.white.opacity(0.3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .onChange(of: buyAmountUsdString) { newValue in
                    if let amount = formatter.number(from:buyAmountUsdString)?.doubleValue {
                        print("amount: \(amount)")
                        buyAmountUsd = amount
                        buyAmountUsdString = priceModel.formatPrice(usd: amount, showSign: false, showUnit: false)
                        isValidInput = true
                    } else {
                        buyAmountUsd = 0
                        isValidInput = false
                    }
                }
                .font(.sfRounded(size: .xl4, weight: .bold))
                .foregroundColor(isValidInput ? .white : .red)
                .frame(width: 150, alignment: .trailing)
                .onTapGesture {
                    isKeyboardActive = true
                    print("Keyboard Activated")
                }
            
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
        HStack(spacing: 8) {
            ForEach([10, 25, 50, 100], id: \.self) { amount in
                amountButton(for: amount)
            }
        }
        .padding(.top, 10)
    }
    
    private func amountButton(for pct: Int) -> some View {
        Button(action: {
            updateBuyAmount(userModel.balanceLamps * pct / 100)
        }) {
            Text(pct == 100 ? "MAX" : "\(pct)%")
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
