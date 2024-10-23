//
//  BuySellForm.swift
//  Tub
//
//  Created by Henry on 9/27/24.
//
import SwiftUI

struct BuySellForm: View {
    @EnvironmentObject var userModel: UserModel
    @ObservedObject var tokenModel: TokenModel
    @Binding var activeTab: String
    @Binding var showBuySheet: Bool
    
    func handleSell(completion: ((Bool) -> Void)?) {
        tokenModel.sellTokens(completion: {success in
            if success {
                activeTab = "buy"
            }
            completion?(success)
        })
    }
    
    var body: some View {
        VStack {
            if userModel.userId == "" {
                Text("Register to trade")
                    .font(.title)
                    .foregroundColor(.yellow)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if activeTab == "buy" {
                Button(action: {
                    showBuySheet = true
                }) {
            Text("Buy")
                .font(.sfRounded(size: .xl, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(AppColors.primaryPurple.opacity(0.4))
                .cornerRadius(26)
            }.offset(y:10)
            } else {
                SellForm(tokenModel: tokenModel, onSell: handleSell)
            }
        }
    }
}

#Preview {
    
    @Previewable @AppStorage("userId") var userId: String = ""
    @Previewable @State var activeTab: String = "buy"
    @Previewable @State var showSheet = false
    @ObservedObject var  tokenModel = TokenModel(userId: userId, tokenId: mockTokenId)

    VStack {
        BuySellForm(tokenModel: tokenModel, activeTab: $activeTab, showBuySheet: $showSheet)
            .environmentObject(UserModel(userId: userId))
           // Buy Sheet View
            if showSheet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSheet = false
                        }
                    }

                BuyForm(isVisible: $showSheet, tokenModel: tokenModel, onBuy: {_,_ in })
                    .transition(.move(edge: .bottom))
                    .zIndex(2) // Ensure it stays on top of everything
                    .offset(y: -200)
            }
    }.frame(maxWidth: .infinity, maxHeight: .infinity) .background(.black).foregroundColor(.white)
}
