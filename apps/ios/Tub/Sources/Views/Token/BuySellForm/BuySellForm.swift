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

// MARK: - Equatable Implementation

/// This extension adds custom equality comparison to BuySellForm.
/// It's used to optimize SwiftUI's view updates by preventing unnecessary redraws.
extension BuySellForm: Equatable {
    static func == (lhs: BuySellForm, rhs: BuySellForm) -> Bool {
        lhs.tokenModel.tokenId == rhs.tokenModel.tokenId
    }
}
