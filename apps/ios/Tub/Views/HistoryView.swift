//
//  HistoryView.swift
//  Tub
//
//  Created by yixintan on 10/3/24.
//

import SwiftUI

struct HistoryView: View {
    @State private var showFilters = true
    
    var body: some View {
        NavigationView {
            VStack {
                Text("History")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                HStack {
                    Text("Completed")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading, 10.0)
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showFilters.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                
                if showFilters {
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                        }
                        .frame(width: 40.0, height: 40.0)
                        Spacer()
                        ForEach(["Type", "Period", "Amount", "Status"], id: \.self) {
                            filter in
                            Button(action: {}) {
                                Text(filter)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20.0)
                    .offset(y: -5)
                }
                
                
                // Transaction List
                List {
                    ForEach(dummyData.indices, id: \.self) { index in
                        NavigationLink(destination: HistoryDetailsView(transaction: dummyData[index])) {
                            
                            VStack {
                                TransactionRow(transaction: dummyData[index])
                                    .padding(.bottom, 2.0)
                                    .padding(.leading, 10.0)
                                
                                if index != dummyData.count  {
                                    Divider()
                                        .frame(width: 340.0, height: 1.0)
                                        .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.153))
                                }
                            }
                        }
                        .listRowBackground(Color.black)
                    }
                }
                .listStyle(PlainListStyle())
                Spacer()
                    
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .navigationTitle("History")
    }
}
    
struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(transaction.coin)
                .resizable()
                .frame(width: 40, height: 40)
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(transaction.isBuy ? "Buy" : "Sell")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(transaction.coin)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.9254901960784314, blue: 0.5254901960784314))
                }
                
                Text(formatDate(transaction.date))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(formatAmount(transaction.amount))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(transaction.isBuy ? .red : .green)
                
                HStack {
                    Text("\(transaction.quantity, specifier: "%.0f")")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .offset(x:4)
                    
                    Text(transaction.coin)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .offset(x: 12)
        }
        .padding(.bottom, 10.0)
        .background(Color.black)
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
}


struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}

