//
//  TokenInfoCardView.swift
//  Tub
//
//  Created by yixintan on 10/11/24.
//
import SwiftUI

struct TokenInfoCardView: View {
    var tokenModel: TokenModel
    @Binding var isVisible: Bool
    
    @State private var dragOffset: CGFloat = 0.0
    @State private var animatingSwipe: Bool = false
    @State private var isClosing: Bool = false
    
    var body: some View {
        VStack() {
            //Coin
            Capsule()
                .fill(AppColors.white.opacity(0.3))
                .frame(width: 60, height: 4)
                .offset(y:-15)
            
            HStack {
                if tokenModel.token.imageUri != nil {
                    ImageView(imageUri: tokenModel.token.imageUri!, size: 20)
                }
                Text("\(tokenModel.token.name)")
                    .font(.sfRounded(size: .xl, weight: .semibold))
                    .foregroundColor(AppColors.lightYellow)
            }
            .offset(y:-8)
            
            //Info
            VStack(alignment: .leading) {
                //inner rectangle
                VStack(alignment: .leading) {
                    HStack{
                        VStack(alignment: .leading){
                            VStack(alignment: .leading){
                                Text("Market Cap")
                                    .font(.sfRounded(size: .sm, weight: .medium))
                                
                                Text("$544M")
                                    .font(.sfRounded(size: .xl2, weight: .semibold))
                            }.padding(.vertical, 5.0)
                            
                            VStack(alignment: .leading){
                                Text("Holders")
                                    .font(.sfRounded(size: .sm, weight: .medium))
                                Text("23.3K")
                                    .font(.sfRounded(size: .xl2, weight: .semibold))
                            }.padding(.vertical, 5.0)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading){
                            VStack(alignment: .leading){
                                Text("Volume (24h)")
                                    .font(.sfRounded(size: .sm, weight: .medium))
                                Text("$29.0M")
                                    .font(.sfRounded(size: .xl2, weight: .semibold))
                            }.padding(.vertical, 5.0)
                            
                            VStack(alignment: .leading){
                                Text("Circulating Supply")
                                    .font(.sfRounded(size: .sm, weight: .medium))
                                Text("900M")
                                    .font(.sfRounded(size: .xl2, weight: .semibold))
                            }.padding(.vertical, 5.0)
                        }
                        .offset(x:-15)
                    }
                    
                    HStack(alignment: .bottom) {
                        Text("Created")
                            .font(.sfRounded(size: .sm, weight: .regular))
                        Text("28d 20h")
                            .font(.sfRounded(size: .sm, weight: .semibold))
                            .offset(x:-3)
                        Text("ago")
                            .font(.sfRounded(size: .sm, weight: .regular))
                            .offset(x:-8)
                    }
                }
                .padding([.leading, .bottom, .trailing], 24.0)
                .padding(.top, 20.0)
                .foregroundColor(AppColors.white)
                .cornerRadius(10)
                .background(AppColors.darkBlue)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .inset(by: 0.5)
                        .strokeBorder(AppColors.white)
                )
                
                //About
                VStack(alignment: .leading){
                    Text("About")
                        .font(.sfRounded(size: .xl2, weight: .bold))
                    
                    Text("This is what the coin is about. Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.")
                        .font(.sfRounded(size: .sm, weight: .medium))
                }
                .foregroundColor(AppColors.white)
                .padding(.vertical, 10.0)
                
                //Twitter Link
                HStack(alignment: .center){
                    Image("X-logo-white")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(" @ MONKAY")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                }
                .padding(.vertical, 10.0)
                .foregroundColor(AppColors.white)
            }
            .padding(.horizontal, 30.0)
        }
        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.53)
        .transition(.move(edge: .bottom))
        .background(AppColors.darkBlueGradient)
        .cornerRadius(20)
        .offset(y: dragOffset)
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
    TokenInfoCardView(tokenModel: TokenModel(userId: userId, tokenId: mockTokenId), isVisible: $isVisible)
}
