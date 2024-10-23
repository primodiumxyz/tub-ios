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

    VStack {
        BuySellForm(tokenModel: TokenModel(userId: userId, tokenId: mockTokenId), activeTab: $activeTab, showBuySheet: $showSheet)
            .environmentObject(UserModel(userId: userId))
    }.frame(maxWidth: .infinity, maxHeight: .infinity) .background(.black).foregroundColor(.white)
}
