//
//  HistoryView.swift
//  Tub
//
//  Created by yixintan on 10/3/24.
//

import CodexAPI
import SwiftUI
import TubAPI

struct HistoryView: View {

    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel

    @State private var txs: [Transaction]
    @State private var isReady: Bool
    @State private var error: Error?  // Add this line
    @State private var tokenMetadata: [String: TokenMetadata] = [:]  // Cache for token metadata

    struct TokenMetadata {
        let name: String?
        let symbol: String?
        let imageUri: String?
    }

    init(txs: [Transaction]? = []) {
        self._txs = State(initialValue: txs!.isEmpty ? [] : txs!)
        self._isReady = State(initialValue: txs != nil)
        self._error = State(initialValue: nil)  // Add this line
    }

    func fetchTokenMetadata(address: String) async throws -> TokenMetadata {
        let client = await CodexNetwork.shared.apolloClient
        return try await withCheckedThrowingContinuation { continuation in
            client.fetch(
                query: GetTokenMetadataQuery(
                    address: address
                )
            ) { result in
                switch result {
                case .success(let response):
                    if let token = response.data?.token {
                        let metadata = TokenMetadata(
                            name: token.info?.name,
                            symbol: token.info?.symbol,
                            imageUri: token.info?.imageLargeUrl ?? token.info?.imageSmallUrl ?? token.info?
                                .imageThumbUrl ?? nil
                        )
                        continuation.resume(returning: metadata)
                    }
                    else {
                        continuation.resume(throwing: TubError.networkFailure)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchUserTxs(_ walletAddress: String) {
        isReady = false
        error = nil
        let query = GetWalletTransactionsQuery(wallet: walletAddress)

        Network.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
            Task {
                do {
                    switch result {
                    case .success(let graphQLResult):
                        if let tokenTransactions = graphQLResult.data?.token_transaction {
                            var processedTxs: [Transaction] = []

                            for transaction in tokenTransactions {
                                guard let date = formatDateString(transaction.wallet_transaction_data.created_at) else {
                                    continue
                                }

                                if abs(transaction.amount) == 0 {
                                    continue
                                }

                                // Fetch token metadata if not cached
                                if tokenMetadata[transaction.token] == nil {
                                    let metadata = try await fetchTokenMetadata(address: transaction.token)
                                    await MainActor.run {
                                        tokenMetadata[transaction.token] = metadata
                                    }
                                }

                                let metadata = tokenMetadata[transaction.token]
                                let isBuy = transaction.amount >= 0
                                let mint = transaction.token
                                let priceLamps = transaction.token_price
                                let valueLamps = transaction.amount * Int(priceLamps) / Int(1e9)

                                let newTransaction = Transaction(
                                    name: metadata?.name ?? "",
                                    symbol: metadata?.symbol ?? "",
                                    imageUri: metadata?.imageUri ?? "",
                                    date: date,
                                    valueUsd: priceModel.lamportsToUsd(lamports: -valueLamps),
                                    valueLamps: -valueLamps,
                                    quantityTokens: transaction.amount,
                                    isBuy: isBuy,
                                    mint: mint
                                )

                                processedTxs.append(newTransaction)
                            }

                            await MainActor.run {
                                self.txs = processedTxs
                                self.isReady = true
                            }
                        }
                    case .failure(let error):
                        throw error
                    }
                }
                catch {
                    await MainActor.run {
                        self.error = error
                        self.isReady = true
                    }
                }
            }
        }
    }

    var body: some View {
        Group {
            if let error = error {
                ErrorView(error: error)
            }
            else {
                HistoryViewContent(txs: txs, isReady: $isReady)
            }
        }.onAppear {
            if let wallet = userModel.walletAddress { fetchUserTxs(wallet) }
        }
    }
}

struct HistoryViewContent: View {
    var txs: [Transaction]
    @Binding var isReady: Bool
    @State private var filterState = FilterState()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Add padding at the top to make room for the filters
                    Color.clear.frame(height: 44)

                    // Transaction List
                    if !isReady {
                        ProgressView()
                    }
                    else if filteredTransactions().isEmpty {
                        Text("No transactions found")
                            .font(.sfRounded(size: .base, weight: .regular))
                            .foregroundStyle(Color.gray)
                    }
                    else {
                        LazyVStack(spacing: 0) {
                            ForEach(groupTransactions(filteredTransactions()), id: \.date) { group in
                                TransactionGroupRow(group: group)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    Spacer()
                }
            }
            .overlay(
                TransactionFilters(filterState: $filterState)
                    .background(Color.black),
                alignment: .top
            )
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // Helper function to filter transactions
    func filteredTransactions() -> [Transaction] {
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
                        .foregroundStyle(Color("grayLight"))
                    Text(transaction.name.isEmpty ? transaction.mint.truncatedAddress() : transaction.name)
                        .font(.sfRounded(size: .base, weight: .bold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .offset(x: -2)
                }

                Text(formatDate(transaction.date))
                    .font(.sfRounded(size: .xs, weight: .regular))
                    .foregroundStyle(Color.gray)
                    .offset(y: 2)

            }
            Spacer()
            VStack(alignment: .trailing) {
                let price = priceModel.formatPrice(usd: transaction.valueUsd, showSign: true)
                Text(price)
                    .font(.sfRounded(size: .base, weight: .bold))
                    .foregroundStyle(transaction.isBuy ? Color.red : Color.green)

                let quantity = priceModel.formatPrice(lamports: abs(transaction.quantityTokens), showUnit: false)
                HStack {
                    Text(quantity)
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(Color.gray)
                        .offset(x: 4, y: 2)

                    Text(transaction.symbol)
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(Color.gray)
                        .offset(y: 2)
                }
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.gray)
                .offset(x: 12)
        }
        .padding(.bottom, 10.0)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Separate search filter component
struct SearchFilter: View {
    @Binding var filterState: FilterState

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                if filterState.isSearching {
                    filterState.searchText = ""
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    filterState.isSearching.toggle()
                }
            }) {
                Image(systemName: filterState.isSearching ? "xmark.circle.fill" : "magnifyingglass")
                    .foregroundStyle(.primary)
                    .font(.sfRounded(size: .base, weight: .semibold))
            }

            if filterState.isSearching {
                ZStack(alignment: .leading) {
                    if filterState.searchText.isEmpty {
                        Text("Search...")
                            .foregroundStyle(Color.gray)
                            .font(.sfRounded(size: .base, weight: .regular))
                    }
                    TextField("", text: $filterState.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundStyle(Color.white)
                        .frame(width: 100)
                        .font(.sfRounded(size: .base, weight: .regular))
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .buttonStyle(FilterButtonStyle())
    }
}
