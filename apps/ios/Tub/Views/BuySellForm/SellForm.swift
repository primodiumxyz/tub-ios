//
//  SellForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct SellForm: View {
    @ObservedObject var tokenModel: BaseTokenModel
    var onSell : (((Bool) -> Void)?) -> ()

    private func handleSell() {
        let _ = onSell(nil)
    }
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack {
                    Button(action: handleSell) {
                        Text("Sell")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(Color.white.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Text("$\(tokenModel.tokenBalance * (tokenModel.prices.last?.price ?? 0) - tokenModel.tokensBought, specifier: "%.2f")")
                        .foregroundColor(tokenModel.tokenBalance * (tokenModel.prices.last?.price ?? 0) - tokenModel.tokensBought > 0 ? .green : .red)
                }
                Spacer()
            }.padding(12)
        }.frame(width: .infinity, height: 300)
    }
}

#Preview {
    VStack {
        SellForm(tokenModel: MockTokenModel(), onSell: { _ in ()})
    }.frame(maxWidth: .infinity, maxHeight: .infinity) .background(.black).foregroundColor(.white)
}
    
