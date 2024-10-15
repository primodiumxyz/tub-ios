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
                .font(.sfRounded(size: .xl2, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 10.0)
            
            VStack (alignment: .leading, spacing: 20) {
                // Token details
                VStack(alignment: .leading) {
                    Text("Token")
                        .foregroundColor(.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    HStack {
                        Image(transaction.imageUri)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                        
                        Text(transaction.name)
                            .font(.sfRounded(size: .xl, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.9254901960784314, blue: 0.5254901960784314))
                    }
                }

                // Transaction number
                VStack(alignment: .leading) {
                    Text("Transaction number")
                        .foregroundColor(.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("#8612373299412")
                        .foregroundColor(.white)
                        .font(.sfRounded(size: .lg, weight: .regular))
                }
                
                // Order status
                VStack(alignment: .leading) {
                    Text("Order status")
                        .foregroundColor(.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("Filled")
                        .foregroundColor(.white)
                        .font(.sfRounded(size: .lg, weight: .regular))

                }
                
                // Quantity
                VStack(alignment: .leading) {
                    Text("Quantity")
                        .foregroundColor(.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("\(transaction.quantity, specifier: "%.0f") \(transaction.symbol)")
                        .foregroundColor(.white)
                        .font(.sfRounded(size: .lg, weight: .regular))
                }
                
                // Price
                VStack(alignment: .leading) {
                    Text("Price")
                        .foregroundColor(.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text(formatAmount(transaction.value))
                        .foregroundColor(.white)
                        .font(.sfRounded(size: .lg, weight: .regular))
                }
                
                // Date and time of the transaction
                VStack(alignment: .leading) {
                    Text("Filled")
                        .foregroundColor(.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("\(formatDate(transaction.date)) at \(formatTime(transaction.date))")
                        .foregroundColor(.white)
                        .font(.sfRounded(size: .lg, weight: .regular))
                }
                
                // Note section
                VStack(alignment: .leading) {
                    Text("Note")
                        .foregroundColor(.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("-")
                        .foregroundColor(.white)
                        .font(.sfRounded(size: .lg, weight: .regular))

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
    
    // Helper functions to format amount and date
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

}

struct HistoryDetailsView_Previews: PreviewProvider {
    static var previews: some View {
            HistoryDetailsView(transaction: dummyData[0])
        }
}
