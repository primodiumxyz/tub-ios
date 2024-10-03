//
//  HistoryDetailsView.swift
//  Tub
//
//  Created by yixintan on 10/3/24.
//

import SwiftUI

struct HistoryDetailsView: View {
    let transaction: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text(transaction.isBuy ? "Buy Details" : "Sell Details")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 10.0)
            
            VStack (alignment: .leading, spacing: 20) {
                // Coin details
                VStack(alignment: .leading) {
                    Text("Coin")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    HStack {
                        Image(transaction.coin)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                        
                        Text(transaction.coin)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.9254901960784314, blue: 0.5254901960784314))
                    }
                }

                // Transaction number
                VStack(alignment: .leading) {
                    Text("Transaction number")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    Text("#8612373299412")
                        .foregroundColor(.white)
                }
                
                // Order status
                VStack(alignment: .leading) {
                    Text("Order status")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    Text("Filled")
                        .foregroundColor(.white)
                }
                
                // Quantity
                VStack(alignment: .leading) {
                    Text("Quantity")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    Text("\(transaction.quantity) \(transaction.coin)")
                        .foregroundColor(.white)
                }
                
                // Price
                VStack(alignment: .leading) {
                    Text("Price")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    Text(transaction.amount)
                        .foregroundColor(.white)
                }
                
                // Date and time of the transaction
                VStack(alignment: .leading) {
                    Text("Filled")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    Text("Oct 1, 2024 at 9:12am")
                        .foregroundColor(.white)
                }
                
                // Note section
                VStack(alignment: .leading) {
                    Text("Note")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    Text("-")
                        .foregroundColor(.white)
                }
            }
            .padding(.leading, 10.0)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle("History")
        .foregroundColor(.white)
    }
}

struct HistoryDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryDetailsView(transaction: Transaction(coin: "$MONKAY", date: "Oct 1, 2024", amount: "- $320.00", quantity: "2,332,100", isBuy: true))
    }
}
