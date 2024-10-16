//
//  SellForm.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct SellForm: View {
    @ObservedObject var tokenModel: TokenModel
    var onSell : (((Bool) -> Void)?) -> ()

    private func handleSell() {
        let _ = onSell(nil)
    }
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("You Owned")
                            .font(.sfRounded(size: .xs, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("\(tokenModel.tokenBalance.total, specifier: "%.2f") ")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("All time gains")
                            .font(.sfRounded(size: .xs, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        let gains = tokenModel.tokenBalance.total * (tokenModel.prices.last?.price ?? 0) - tokenModel.amountBoughtSol
                        let percentageGain = gains / tokenModel.amountBoughtSol * 100
                        
                        HStack(){
                            Image(systemName: gains > 0 ? "arrow.up" : "arrow.down")
                                .foregroundColor(gains > 0 ? .green : .red)
                                .font(.system(size: 16, weight: .bold))
                            
                            Text(String(format: "$%.2f", gains))
                                .font(.sfRounded(size: .xl, weight: .semibold))
                                .foregroundColor(gains > 0 ? .green : .red)
                                .offset(x:-5)
                            Text(String(format: "(%.2f%%)", percentageGain))
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .foregroundColor(gains > 0 ? .green : .red)
                                .offset(x:-8)
                        }
                    }
                    .frame(width: geometry.size.width * 0.6, alignment: .leading)
                }
                .padding()
                
                Button(action: handleSell) {
                    Text("Sell")
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(red: 0.82, green: 0.31, blue: 0.6))
                        .cornerRadius(26)
                }
                
                Spacer()
            }
        }
    }
}

