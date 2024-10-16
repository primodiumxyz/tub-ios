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
            Spacer()
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
                        .background(AppColors.primaryPurple)
                        .cornerRadius(26)
                }
            } else {
                SellForm(tokenModel: tokenModel, onSell: handleSell)
            }
        }.frame(height:100)
    }
}

#Preview {
    
    @Previewable @AppStorage("userId") var userId: String = ""
    @Previewable @State var activeTab: String = "buy"
    @Previewable @State var showSheet = false
    
    VStack {
        BuySellForm(tokenModel: TokenModel(userId: userId, tokenId: mockTokenId), activeTab: $activeTab, showBuySheet: $showSheet)
            .environmentObject(UserModel(userId: userId))
    }.frame(maxWidth: .infinity, maxHeight: .infinity) .background(.black).foregroundColor(AppColors.white)
}
