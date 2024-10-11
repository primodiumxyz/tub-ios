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
    
    var body: some View {
        VStack() {
            //Coin
            HStack {
                Text("$\(tokenModel.token.name)")
                    .font(.sfRounded(size: .xl2, weight: .semibold))
                    .foregroundColor(.white)
            }
            
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
                            }.padding(5.0)
                            
                            VStack(alignment: .leading){
                                Text("Holders")
                                    .font(.sfRounded(size: .sm, weight: .medium))
                                Text("23.3 K")
                                .font(.sfRounded(size: .xl2, weight: .semibold))                        }.padding(5.0)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading){
                            VStack(alignment: .leading){
                                Text("Volume (24h)")
                                    .font(.sfRounded(size: .sm, weight: .medium))
                                Text("$29.0M")
                                .font(.sfRounded(size: .xl2, weight: .semibold))                        }.padding(5.0)
                            
                            VStack(alignment: .leading){
                                Text("Circulating Supply")
                                    .font(.sfRounded(size: .sm, weight: .medium))
                                Text("900M")
                                .font(.sfRounded(size: .xl2, weight: .semibold))                        }.padding(5.0)
                        }
                    }
                    
                    HStack(alignment: .bottom) {
                        Text("Created")
                            .font(.sfRounded(size: .base, weight: .medium))
                        Text("28d 20h")
                            .font(.sfRounded(size: .base, weight: .semibold))
                        Text("ago")
                            .font(.sfRounded(size: .base, weight: .medium))
                            .offset(x:-5)
                    }
                }
                .padding([.leading, .bottom, .trailing], 24.0)
                .padding(.top, 20.0)
                .foregroundColor(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .inset(by: 0.5)
                        .strokeBorder(.white)
                )
                
                //About
                VStack(alignment: .leading){
                    Text("About")
                        .font(.sfRounded(size: .xl2, weight: .bold))
                    
                    Text("This is what the coin is about. Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.")
                        .font(.sfRounded(size: .base, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10.0)
                
                //Twitter Link
                HStack(alignment: .center){
                    Image(systemName:"network")
                    Text("@ MONKAY")
                        .font(.sfRounded(size: .lg, weight: .semibold))
                }
                .padding(.vertical, 10.0)
                .foregroundColor(.white)
            }
            .padding(.horizontal, 30.0)
        }
        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.53) // Adjust height for the card
        .transition(.move(edge: .bottom))
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.18, green: 0.08, blue: 0.37), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.2), location: 0.52),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        )
        .cornerRadius(20)
        .padding(.horizontal, 0) 
    }
}

#Preview {
    @Previewable @AppStorage("userId") var userId: String = ""
    @State var isVisible = true
    TokenInfoCardView(tokenModel: TokenModel(userId: userId, tokenId: mockTokenId), isVisible: $isVisible)
}
