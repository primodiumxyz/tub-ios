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
    @State private var sellAmount: Double = 0.0
    @Binding var activeTab: String

    func handleBuy(amount: Double, completion: ((Bool) -> Void)?) {
        tokenModel.buyTokens(buyAmountSol: amount, completion: {success in
            if success {
                activeTab = "sell"
            }
            completion?(success)
        })
    }
    
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
                BuyForm(tokenModel: tokenModel, onBuy: handleBuy)
            } else {
                SellForm(tokenModel: tokenModel, onSell: handleSell)
            }
        }.frame(width: .infinity, height: 300)
    }
}

#Preview {
    
    @Previewable @AppStorage("userId") var userId: String = ""
    @Previewable @State var activeTab: String = "buy"
    
    VStack {
        BuySellForm(tokenModel: TokenModel(userId: userId, tokenId: mockTokenId), activeTab: $activeTab)
            .environmentObject(UserModel(userId: userId))
    }.frame(maxWidth: .infinity, maxHeight: .infinity) .background(.black).foregroundColor(.white)
}

