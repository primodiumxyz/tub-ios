//
//  HistoryView.swift
//  Tub
//
//  Created by yixintan on 10/3/24.
//

import SwiftUI

struct HistoryView: View {
    var txs: [Transaction]
    @State private var showFilters = true
    
    // Filter state
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var selectedBuy: Bool = true
    @State private var selectedSell: Bool = true
    @State private var selectedPeriod: String = "All"
    @State private var selectedAmountRange: String = "All"
    @State private var selectedFilled: Bool = true
    @State private var selectedUnfilled: Bool = true
    
    
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button(action: {
                                withAnimation { isSearching.toggle()}
                            }) {
                                Image(systemName: isSearching ? "xmark.circle.fill" : "magnifyingglass")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                            
                            if isSearching {
                                ZStack {
                                    if searchText.isEmpty {
                                        Text("Search...")
                                            .foregroundColor(.gray)
                                            .offset(x:-14)
                                    }
                                    TextField("", text: $searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .foregroundColor(.white)
                                        .frame(width: 100, height: 44)
                                        .cornerRadius(0)
                                        .transition(.move(edge: .trailing))
                                }
                            }
                            
                            // Type Filter Dropdown (Buy/Sell Checkboxes)
                            Menu {
                                Toggle(isOn: $selectedBuy) { Text("Buy") }
                                Toggle(isOn: $selectedSell) { Text("Sell") }
                            } label: {
                                Text(typeFilterLabel())
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6.0)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                            
                            // Period Filter
                            Menu {
                                Button(action: { selectedPeriod = "All" }) { Text("All") }
                                Button(action: { selectedPeriod = "Today" }) { Text("Today") }
                                Button(action: { selectedPeriod = "This Week" }) { Text("This Week") }
                                Button(action: { selectedPeriod = "This Month" }) { Text("This Month") }
                                Button(action: { selectedPeriod = "This Year" }) { Text("This Year") }
                            } label: {
                                Text("Period: \(selectedPeriod)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                            
                            // Status Filter
                            Menu {
                                Toggle(isOn: $selectedFilled) { Text("Filled") }
                                Toggle(isOn: $selectedUnfilled) { Text("Unfilled") }
                            } label: {
                                Text(statusFilterLabel())
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                            
                            // Amount Filter
                            Menu {
                                Button(action: { selectedAmountRange = "All" }) { Text("All") }
                                Button(action: { selectedAmountRange = "< $100" }) { Text("< $100") }
                                Button(action: { selectedAmountRange = "> $100" }) { Text("> $100") }
                            } label: {
                                Text("Amount: \(selectedAmountRange)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20.0)
                        .frame(height: 40.0)
                        .offset(y: -5)
                    }
                }
                
                
                // Transaction List
                List {
                    ForEach(filteredTransactions(), id: \.id) { transaction in
                        NavigationLink(destination: HistoryDetailsView(transaction: transaction)) {
                            
                            VStack {
                                TransactionRow(transaction: transaction)
                                    .padding(.bottom, 2.0)
                                    .padding(.leading, 10.0)
                                
                                if transaction != txs.last  {
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
    
    // For Type filter label
    func typeFilterLabel() -> String {
        if selectedBuy && selectedSell {
            return "Type: All"
        } else if selectedBuy {
            return "Type: Buy"
        } else if selectedSell {
            return "Type: Sell"
        } else {
            return "Type: None"
        }
    }
    
    // For Status filter label
    func statusFilterLabel() -> String {
        if selectedFilled && selectedUnfilled {
            return "Status: All"
        } else if selectedFilled {
            return "Status: Filled"
        } else if selectedUnfilled {
            return "Status: Unfilled"
        } else {
            return "Status: None"
        }
    }
    
    // Helper function to filter transactions
    func filteredTransactions() -> [Transaction] {
        var filteredData = txs
                
        // Filter by search text
        if !searchText.isEmpty {
            filteredData = filteredData.filter { transaction in
                // Remove "$" from the coin name
                let cleanedCoin = transaction.coin.replacingOccurrences(of: "$", with: "").lowercased()
                return cleanedCoin.hasPrefix(searchText.lowercased())
            }
        }
        
        // Filter by Type (checkboxes)
        if selectedBuy && !selectedSell {
            filteredData = filteredData.filter { $0.isBuy }
        } else if selectedSell && !selectedBuy {
            filteredData = filteredData.filter { !$0.isBuy }
        } else if !selectedBuy && !selectedSell {
            filteredData = []
        }
        
        // Filter by Period
        if selectedPeriod != "All" {
            switch selectedPeriod {
            case "Today":
                filteredData = filteredData.filter { Calendar.current.isDateInToday($0.date) }
            case "This Week":
                filteredData = filteredData.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            case "This Month":
                filteredData = filteredData.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            case "This Year":
                filteredData = filteredData.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .year) }
            default:
                break
            }
        }

        // Filter by Status (checkboxes)
        if selectedFilled && !selectedUnfilled {
            filteredData = filteredData.filter { _ in true }
        } else if selectedUnfilled && !selectedFilled {
            filteredData = filteredData.filter { _ in false }
        } else if !selectedFilled && !selectedUnfilled {
            filteredData = []
        }
        
        // Filter by Amount
        if selectedAmountRange != "All" {
            switch selectedAmountRange {
            case "< $100":
                filteredData = filteredData.filter { abs($0.amount) < 100 }
            case "> $100":
                filteredData = filteredData.filter { abs($0.amount) > 100 }
            default:
                break
            }
        }
        
        return filteredData
    }
}
    
struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
//            Image(transaction.coinUri)
//                .resizable()
//                .frame(width: 40, height: 40)
//                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(transaction.isBuy ? "Buy" : "Sell")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
//                    Text(transaction.coinUri)
//                        .font(.system(size: 16, weight: .bold))
//                        .foregroundColor(Color(red: 1.0, green: 0.9254901960784314, blue: 0.5254901960784314))
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
                    
//                    Text(transaction.coin)
//                        .font(.system(size: 12))
//                        .foregroundColor(.gray)
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
        HistoryView(txs: dummyData)
    }
}

