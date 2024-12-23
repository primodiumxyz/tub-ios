//
//  HistoryView.swift
//  Tub
//
//  Created by yixintan on 10/3/24.
//

import SwiftUI
import TubAPI


struct HistoryView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    
    func handleFetchTxs(hardRefresh: Bool) {
        Task {
            try? await userModel.refreshTxs(hard: hardRefresh)
        }
    }
    
    @State private var filterState = FilterState()

    var body: some View {
            VStack(spacing: 0) {
                // Transaction List
                if userModel.txs == nil {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                else if filteredTransactions().isEmpty {
                    TransactionFilters(filterState: $filterState)
                        .background(Color(UIColor.systemBackground))
                    Text("No transactions found")
                        .padding()
                        .font(.sfRounded(size: .base, weight: .regular))
                        .foregroundStyle(Color.gray)
                } else {
                    TransactionFilters(filterState: $filterState)
                        .background(Color(UIColor.systemBackground))
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(groupTransactions(filteredTransactions()), id: \.date) { group in
                                TransactionGroupRow(group: group)
                        }
                    }
                    .padding(.horizontal, 16)
            }
                }
        }
            .onAppear{
                handleFetchTxs(hardRefresh: false)
            }
            .refreshable(action: {handleFetchTxs(hardRefresh: true)})
        
        .navigationTitle("All Trades")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Helper function to filter transactions
    func filteredTransactions() -> [TransactionData] {
        guard let txs = userModel.txs else { return [] }
        var filteredData = txs

        // Filter by search text
        if !filterState.searchText.isEmpty {
            filteredData = filteredData.filter { transaction in
                let cleanedSymbol = transaction.symbol.replacingOccurrences(of: "$", with: "").lowercased()
                return cleanedSymbol.hasPrefix(filterState.searchText.lowercased())
            }
        }

        // Filter by Type (checkboxes)
        if filterState.selectedBuy && !filterState.selectedSell {
            filteredData = filteredData.filter { $0.isBuy }
        }
        else if filterState.selectedSell && !filterState.selectedBuy {
            filteredData = filteredData.filter { !$0.isBuy }
        }
        else if !filterState.selectedBuy && !filterState.selectedSell {
            filteredData = []
        }

        // Filter by Period
        if filterState.selectedPeriod != "All" {
            switch filterState.selectedPeriod {
            case "Today":
                filteredData = filteredData.filter { Calendar.current.isDateInToday($0.date) }
            case "This Week":
                filteredData = filteredData.filter {
                    Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
                }
            case "This Month":
                filteredData = filteredData.filter {
                    Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
                }
            case "This Year":
                filteredData = filteredData.filter {
                    Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .year)
                }
            default:
                break
            }
        }

        // Filter by Status (checkboxes)
        if filterState.selectedFilled && !filterState.selectedUnfilled {
            filteredData = filteredData.filter { _ in true }
        }
        else if filterState.selectedUnfilled && !filterState.selectedFilled {
            filteredData = filteredData.filter { _ in false }
        }
        else if !filterState.selectedFilled && !filterState.selectedUnfilled {
            filteredData = []
        }

        // Filter by Amount
        if filterState.selectedAmountRange != "All" {
            switch filterState.selectedAmountRange {
            case "< $100":
                filteredData = filteredData.filter { abs($0.valueUsd) < 100.0 }
            case "> $100":
                filteredData = filteredData.filter { abs($0.valueUsd) > 100.0 }
            default:
                break
            }
        }

        return filteredData
    }

    // Helper function to group transactions
func groupTransactions(_ transactions: [TransactionData]) -> [TransactionGroup] {
    let grouped = Dictionary(grouping: transactions) { transaction in
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: transaction.date)
        return "\(transaction.mint)_\(date)"
    }

    return grouped.map { _, transactions in
        let netProfit = transactions.reduce(0.0) { sum, tx in
            sum + tx.valueUsd
        }

        let firstTx = transactions.sorted { $0.date > $1.date }.first!

        return TransactionGroup(
            transactions: transactions.sorted { $0.date > $1.date },
            netProfit: netProfit,
            date: firstTx.date,
            token: firstTx.mint,
            symbol: firstTx.symbol,
            imageUri: firstTx.imageUri
        )
    }.sorted { $0.date > $1.date }
}
}

struct FilterState {
    var searchText: String = ""
    var isSearching: Bool = false
    var selectedBuy: Bool = true
    var selectedSell: Bool = true
    var selectedPeriod: String = "All"
    var selectedAmountRange: String = "All"
    var selectedFilled: Bool = true
    var selectedUnfilled: Bool = true
}

struct TransactionFilters: View {
    @Binding var filterState: FilterState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Search Button and Field
                SearchFilter(filterState: $filterState)

                // Type Filter
                Menu {
                    Toggle(isOn: $filterState.selectedBuy) { Text("Buy") }
                    Toggle(isOn: $filterState.selectedSell) { Text("Sell") }
                } label: {
                    FilterButton(text: typeFilterLabel())
                }

                // Period Filter
                Menu {
                    ForEach(["All", "Today", "This Week", "This Month", "This Year"], id: \.self) { period in
                        Button(action: { filterState.selectedPeriod = period }) {
                            Text(period)
                        }
                    }
                } label: {
                    FilterButton(text: "Period: \(filterState.selectedPeriod)")
                }

                // Status Filter
                Menu {
                    Toggle(isOn: $filterState.selectedFilled) { Text("Filled") }
                    Toggle(isOn: $filterState.selectedUnfilled) { Text("Unfilled") }
                } label: {
                    FilterButton(text: statusFilterLabel())
                }

                // Amount Filter
                Menu {
                    ForEach(["All", "< $100", "> $100"], id: \.self) { amount in
                        Button(action: { filterState.selectedAmountRange = amount }) {
                            Text(amount)
                        }
                    }
                } label: {
                    FilterButton(text: "Amount: \(filterState.selectedAmountRange)")
                }
            }
            .padding()
            .foregroundStyle(.tubTextSecondary)
        }
        .frame(height: 44)
    }

    func typeFilterLabel() -> String {
        if filterState.selectedBuy && filterState.selectedSell {
            return "Type: All"
        }
        else if filterState.selectedBuy {
            return "Type: Buy"
        }
        else if filterState.selectedSell {
            return "Type: Sell"
        }
        else {
            return "Type: None"
        }
    }

    func statusFilterLabel() -> String {
        if filterState.selectedFilled && filterState.selectedUnfilled {
            return "Status: All"
        }
        else if filterState.selectedFilled {
            return "Status: Filled"
        }
        else if filterState.selectedUnfilled {
            return "Status: Unfilled"
        }
        else {
            return "Status: None"
        }
    }
}



// Separate search filter component
struct SearchFilter: View {
    @Binding var filterState: FilterState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: filterState.isSearching ? "xmark.circle.fill" : "magnifyingglass")
                .foregroundStyle(.primary)
                .font(.sfRounded(size: .base, weight: .semibold))
                .onTapGesture {
                    if filterState.isSearching {
                        filterState.searchText = ""
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        filterState.isSearching.toggle()
                    }
                }

            if filterState.isSearching {
                ZStack(alignment: .leading) {
                    if filterState.searchText.isEmpty {
                        Text("Search...")
                            .foregroundStyle(.secondary)
                            .font(.sfRounded(size: .base, weight: .regular))
                    }
                    TextField("", text: $filterState.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundStyle(.primary)
                        .frame(width: 100)
                        .font(.sfRounded(size: .base, weight: .regular))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.tubNeutral, lineWidth: 1)
        )
        .onTapGesture {
            if !filterState.isSearching {
                withAnimation(.easeInOut(duration: 0.2)) {
                    filterState.isSearching.toggle()
                }
            }
        }
    }
}

