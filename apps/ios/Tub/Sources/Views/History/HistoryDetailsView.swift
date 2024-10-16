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
                .foregroundColor(AppColors.white)
                .padding(.leading, 10.0)
            
            VStack (alignment: .leading, spacing: 20) {
                // Token details
                VStack(alignment: .leading) {
                    Text("Token")
                        .foregroundColor(AppColors.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    HStack {
                        Image(transaction.imageUri)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                        
                        Text(transaction.name)
                            .font(.sfRounded(size: .xl, weight: .bold))
                            .foregroundColor(AppColors.lightYellow)
                    }
                }

                // Transaction number
                VStack(alignment: .leading) {
                    Text("Transaction number")
                        .foregroundColor(AppColors.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("#8612373299412")
                        .foregroundColor(AppColors.white)
                        .font(.sfRounded(size: .lg, weight: .regular))
                }
                
                // Order status
                VStack(alignment: .leading) {
                    Text("Order status")
                        .foregroundColor(AppColors.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("Filled")
                        .foregroundColor(AppColors.white)
                        .font(.sfRounded(size: .lg, weight: .regular))

                }
                
                // Quantity
                VStack(alignment: .leading) {
                    Text("Quantity")
                        .foregroundColor(AppColors.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("\(transaction.quantity, specifier: "%.0f") \(transaction.symbol)")
                        .foregroundColor(AppColors.white)
                        .font(.sfRounded(size: .lg, weight: .regular))
                }
                
                // Price
                VStack(alignment: .leading) {
                    Text("Price")
                        .foregroundColor(AppColors.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text(formatAmount(transaction.value))
                        .foregroundColor(AppColors.white)
                        .font(.sfRounded(size: .lg, weight: .regular))
                }
                
                // Date and time of the transaction
                VStack(alignment: .leading) {
                    Text("Filled")
                        .foregroundColor(AppColors.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("\(formatDate(transaction.date)) at \(formatTime(transaction.date))")
                        .foregroundColor(AppColors.white)
                        .font(.sfRounded(size: .lg, weight: .regular))
                }
                
                // Note section
                VStack(alignment: .leading) {
                    Text("Note")
                        .foregroundColor(AppColors.gray)
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text("-")
                        .foregroundColor(AppColors.white)
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
        .foregroundColor(AppColors.white)
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
