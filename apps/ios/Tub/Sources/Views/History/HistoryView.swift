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

    @State private var txs: [TransactionData]
    @State private var isReady: Bool
    @State private var error: Error?
    @State private var tokenMetadata: [String: TokenMetadata] = [:]  // Cache for token metadata

    struct TokenMetadata {
        let name: String
        let symbol: String
        let imageUri: String?
    }

    init(txs: [TransactionData]? = []) {
        self._txs = State(initialValue: txs!.isEmpty ? [] : txs!)
        self._isReady = State(initialValue: txs != nil)
        self._error = State(initialValue: nil)  // Add this line
    }

    func fetchTokenMetadata(addresses: [String]) async throws -> [String: TokenMetadata] {
        // Find which tokens we need to fetch (not in cache)
        let uncachedTokens = addresses.filter { !tokenMetadata.keys.contains($0) }
        
        // If all tokens are cached, return existing metadata
        if uncachedTokens.isEmpty {
            return tokenMetadata
        }
        
        // Only fetch metadata for uncached tokens
        return try await withCheckedThrowingContinuation { continuation in
            Network.shared.apollo.fetch(
                query: GetTokensMetadataQuery(tokens: uncachedTokens)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let _ = graphQLResult.errors {
                        continuation.resume(throwing: TubError.unknown)
                        return
                    }
                    
                    // Create new metadata from fetched data
                    var updatedMetadata = self.tokenMetadata
                    
                    if let tokens = graphQLResult.data?.token_metadata_formatted {
                        for metadata in tokens {
                            do {
                                updatedMetadata[metadata.mint] = TokenMetadata(
                                    name: metadata.name,
                                    symbol: metadata.symbol,
                                    imageUri: metadata.image_uri
                                )
                            }
                        }
                        continuation.resume(returning: updatedMetadata)
                    } else {
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
                        if let tokenTransactions = graphQLResult.data?.transactions {
                            // Get unique token addresses
                            let uniqueTokens = Set(tokenTransactions.map { $0.token_mint })
                            
                            // Fetch all metadata in one call
                            let metadata = try await fetchTokenMetadata(addresses: Array(uniqueTokens))
                            await MainActor.run {
                                self.tokenMetadata = metadata
                            }
                            
                            var processedTxs: [TransactionData] = []

                            for transaction in tokenTransactions {
                                guard let date = formatDateString(transaction.created_at)
                                else {
                                    continue
                                }

                                if abs(transaction.token_amount) == 0 {
                                    continue
                                }

                                // Fetch token metadata if not cached
                                if tokenMetadata[transaction.token_mint] == nil {
                                    let metadata = try await fetchTokenMetadata(address: transaction.token_mint)
                                    await MainActor.run {
                                        tokenMetadata[transaction.token_mint] = metadata
                                    }
                                }

                                let mint = transaction.token_mint
                                let metadata = tokenMetadata[mint]
                                let isBuy = transaction.token_amount >= 0
                                let priceUsdc = transaction.token_price_usd
                                let valueUsdc = Int(transaction.token_amount) * Int(priceUsdc) / Int(1e9)

                                let newTransaction = TransactionData(
                                    name: metadata?.name ?? "",
                                    symbol: metadata?.symbol ?? "",
                                    imageUri: metadata?.imageUri ?? "",
                                    date: date,
                                    valueUsd: priceModel.usdcToUsd(usdc: -valueUsdc),
                                    valueUsdc: -valueUsdc,
                                    quantityTokens: Int(transaction.token_amount),
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
                HistoryViewContent(
                    txs: txs,
                    isReady: $isReady,
                    fetchUserTxs: fetchUserTxs
                )
            }
        }.onAppear {
            if let wallet = userModel.walletAddress { fetchUserTxs(wallet) }
        }
    }
}

struct HistoryViewContent: View {
    @EnvironmentObject private var userModel: UserModel
    var txs: [TransactionData]
    @Binding var isReady: Bool
    @State private var filterState = FilterState()
    var fetchUserTxs: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Transaction List
                if !isReady {
                    ProgressView()
                }
                else if filteredTransactions().isEmpty {
                    TransactionFilters(filterState: $filterState)
                        .background(Color(UIColor.systemBackground))
                    Text("No transactions found")
                        .padding()
                        .font(.sfRounded(size: .base, weight: .regular))
                        .foregroundStyle(Color.gray)
                }
                else {
                    TransactionFilters(filterState: $filterState)
                        .background(Color(UIColor.systemBackground))
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
        .refreshable {
            if let wallet = userModel.walletAddress {
                fetchUserTxs(wallet)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Helper function to filter transactions
    func filteredTransactions() -> [TransactionData] {
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
    let transaction: TransactionData
    @EnvironmentObject private var priceModel: SolPriceModel

    var body: some View {
        HStack {
            ImageView(imageUri: transaction.imageUri, size: 40)
                .cornerRadius(8)

            VStack(alignment: .leading) {
                HStack {
                    Text(transaction.isBuy ? "Buy" : "Sell")
                        .font(.sfRounded(size: .base, weight: .bold))
                        .foregroundStyle(.tubNeutral)
                    Text(transaction.name.isEmpty ? transaction.mint.truncatedAddress() : transaction.name)
                        .font(.sfRounded(size: .base, weight: .bold))
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

                let quantity = priceModel.formatPrice(
                    lamports: abs(transaction.quantityTokens),
                    showUnit: false
                )
                HStack {
                    Text(quantity)
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(.secondary)
                        .offset(x: 4, y: 2)

                    Text(transaction.symbol)
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(.secondary)
                        .offset(y: 2)
                }
            }
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
