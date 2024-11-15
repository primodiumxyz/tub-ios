//
//  HistoryView.swift
//  Tub
//
//  Created by yixintan on 10/3/24.
//

import SwiftUI
import TubAPI

struct HistoryView : View {
    
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    
    
    @State private var txs: [Transaction]
    @State private var loading : Bool
    @State private var error: Error? // Add this line
    
    init(txs: [Transaction]? = []) {
        self._txs = State(initialValue: txs!.isEmpty ? [] : txs!)
        self._loading = State(initialValue: txs == nil)
        self._error = State(initialValue: nil) // Add this line
    }
    
    func fetchUserTxs(_ userId: String) {
        guard let walletAddress = userModel.walletAddress else { return }
        loading = true
        error = nil // Reset error state
        let query = GetWalletTransactionsQuery(wallet: walletAddress)
        
        Network.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
            DispatchQueue.main.async {
                self.loading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let tokenTransactions = graphQLResult.data?.token_transaction {
                        self.txs = tokenTransactions.reduce(into: []) { result, transaction in
                            guard let date = formatDateString(transaction.wallet_transaction_data.created_at) else {
                                return
                            }
                            if (abs(transaction.amount) == 0) {
                                return
                            }
                            
                            let isBuy = transaction.amount >= 0
                            let symbol = transaction.token_data.symbol
                            let name = transaction.token_data.name
                            let mint = transaction.token_data.mint
                            
                            let imageUri = transaction.token_data.uri?.replacingOccurrences(of: "https://cdn.helius-rpc.com/cdn-cgi/image//", with: "").replacingOccurrences(of: "cf-ipfs.com", with: "ipfs.io") ?? "" // Helius cdn link doesn't work out for now
                            let price = transaction.token_price?.price ?? 0
                            
                            var valueLamps = 0
                            let maxSafeValue = transaction.amount > 0 ? Int.max / abs(transaction.amount) : 0
                            if Double(price) > Double(maxSafeValue) {
                                valueLamps = maxSafeValue / Int(1e9)
                            } else {
                                valueLamps = Int(Double(price) * Double(transaction.amount) / Double(1e9))
                            }
                                
                            let newTransaction = Transaction(
                                name: name ?? "",
                                symbol: symbol ?? "",
                                imageUri: imageUri,
                                date: date,
                                valueUsd: priceModel.lamportsToUsd(lamports: -valueLamps),
                                valueLamps: -valueLamps,
                                quantityTokens: transaction.amount,
                                isBuy: isBuy,
                                mint: mint
                            )
                                
                            result.append(newTransaction)
                        }
                    } else if let error = graphQLResult.errors?.first {
                        print(error)
                        self.error = error
                    } else {
                        self.txs = []
                    }
                case .failure(let error):
                    print("Error fetching transactions: \(error)")
                    self.error = error
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if loading == true {
                LoadingView(identifier: "HistoryView - loading")
            } else if let error = error {
                ErrorView(error: error)
            } else {
                HistoryViewContent(txs: txs)
            }
        }.onAppear {
            if let userId = userModel.userId { fetchUserTxs(userId) }
        }
    }
}



struct HistoryViewContent: View {
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
                    .font(.sfRounded(size: .xl2, weight: .bold))
                    .foregroundColor(AppColors.white)
                
                HStack {
                    Text("Completed")
                        .font(.sfRounded(size: .xl2, weight: .bold))
                        .foregroundColor(AppColors.white)
                        .padding(.leading, 10.0)
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showFilters.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .foregroundColor(AppColors.white)
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
                                    .foregroundColor(AppColors.white)
                                    .font(.sfRounded(size: .lg, weight: .semibold))
                                
                            }
                            
                            if isSearching {
                                ZStack {
                                    if searchText.isEmpty {
                                        Text("Search...")
                                            .foregroundColor(AppColors.gray)
                                            .font(.sfRounded(size: .base, weight: .regular))
                                            .offset(x:-14)
                                    }
                                    TextField("", text: $searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .foregroundColor(AppColors.white)
                                        .frame(width: 100, height: 44)
                                        .cornerRadius(0)
                                        .transition(.move(edge: .trailing))
                                        .font(.sfRounded(size: .base, weight: .regular))
                                }
                            }
                            
                            // Type Filter Dropdown (Buy/Sell Checkboxes)
                            Menu {
                                Toggle(isOn: $selectedBuy) { Text("Buy") }
                                Toggle(isOn: $selectedSell) { Text("Sell") }
                            } label: {
                                Text(typeFilterLabel())
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundColor(AppColors.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6.0)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppColors.lightGray, lineWidth: 1)
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
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundColor(AppColors.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppColors.lightGray, lineWidth: 1)
                                    )
                            }
                            
                            // Status Filter
                            Menu {
                                Toggle(isOn: $selectedFilled) { Text("Filled") }
                                Toggle(isOn: $selectedUnfilled) { Text("Unfilled") }
                            } label: {
                                Text(statusFilterLabel())
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundColor(AppColors.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppColors.lightGray, lineWidth: 1)
                                    )
                            }
                            
                            // Amount Filter
                            Menu {
                                Button(action: { selectedAmountRange = "All" }) { Text("All") }
                                Button(action: { selectedAmountRange = "< $100" }) { Text("< $100") }
                                Button(action: { selectedAmountRange = "> $100" }) { Text("> $100") }
                            } label: {
                                Text("Amount: \(selectedAmountRange)")
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundColor(AppColors.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppColors.lightGray, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20.0)
                        .frame(height: 40.0)
                        .offset(y: -5)
                    }
                }
                
                
                // Transaction List
                if filteredTransactions().isEmpty {
                    Text("No transactions found")
                        .font(.sfRounded(size: .base, weight: .regular))
                        .foregroundColor(AppColors.gray)
                } else {
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
                                            .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.2))
                                    }
                                }
                            }
                            .listRowBackground(Color.black)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
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
                let cleanedSymbol = transaction.symbol.replacingOccurrences(of: "$", with: "").lowercased()
                return cleanedSymbol.hasPrefix(searchText.lowercased())
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
                filteredData = filteredData.filter { abs($0.valueUsd) < 100 }
            case "> $100":
                filteredData = filteredData.filter { abs($0.valueUsd) > 100 }
            default:
                break
            }
        }
        
        return filteredData
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @EnvironmentObject private var priceModel: SolPriceModel
    
    var body: some View {
        HStack {
            ImageView(imageUri: transaction.imageUri, size: 40)
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(transaction.isBuy ? "Buy" : "Sell")
                        .font(.sfRounded(size: .base, weight: .bold))
                        .foregroundColor(AppColors.lightGray)
                    Text(transaction.name.isEmpty ? transaction.mint.truncatedAddress() : transaction.name)
                        .font(.sfRounded(size: .base, weight: .bold))
                        .foregroundColor(AppColors.white)
                        .offset(x:-2)
                }
                
                Text(formatDate(transaction.date))
                    .font(.sfRounded(size: .xs, weight: .regular))
                    .foregroundColor(AppColors.gray)
                    .offset(y:2)
                
            }
            Spacer()
            VStack(alignment: .trailing) {
                HStack {
                    Text(priceModel.formatPrice(usd: transaction.valueUsd, showSign: true))
                        .font(.sfRounded(size: .base, weight: .bold))
                        .foregroundColor(transaction.isBuy ? AppColors.red: AppColors.green)
                }
                
                HStack {
                    Text(priceModel.formatPrice(lamports: abs(transaction.quantityTokens), showUnit: false))
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundColor(AppColors.gray)
                        .offset(x:4, y:2)
                    
                    Text(transaction.symbol)
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundColor(AppColors.gray)
                        .offset(y:2)
                }
            }
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.gray)
                .offset(x: 12)
        }
        .padding(.bottom, 10.0)
        .background(Color.black)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


#Preview {
    @Previewable @StateObject var errorHandler = ErrorHandler()
    @Previewable @StateObject var priceModel = SolPriceModel.shared
    HistoryView(txs: dummyData).environmentObject(priceModel).environmentObject(errorHandler)
}

