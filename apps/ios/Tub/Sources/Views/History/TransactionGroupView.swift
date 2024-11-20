import SwiftUI
import TubAPI

struct TransactionGroup {
    let transactions: [Transaction]
    let netProfit: Double
    let date: Date
    let token: String
    let symbol: String
    let imageUri: String
}

struct TransactionGroupRow: View {
    let group: TransactionGroup
    @State private var isExpanded = false
    @EnvironmentObject private var priceModel: SolPriceModel
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { 
                withAnimation { isExpanded.toggle() }
            }) {
                HStack(alignment: .center) {
                    ImageView(imageUri: group.imageUri, size: 40)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text(group.symbol)
                            .font(.sfRounded(size: .base, weight: .bold))
                            .foregroundColor(AppColors.white)
                        
                        if !isExpanded {
                            Text(formatDate(group.date)) 
                                .font(.sfRounded(size: .sm, weight: .regular))
                                .foregroundColor(AppColors.gray)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        let price = priceModel.formatPrice(usd: group.netProfit, showSign: true)
                        Text(price)
                            .font(.sfRounded(size: .base, weight: .bold))
                            .foregroundColor(group.netProfit >= 0 ? AppColors.green : AppColors.red)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppColors.gray)
                        .padding(.leading, 8)
                        
                }
                .padding(.vertical, 12)
            }
        }
        .background(Color.black)
        
        // Expanded content in a separate container
        if isExpanded {
            VStack(spacing: 0) {
                ForEach(group.transactions, id: \.id) { transaction in
                    TransactionDetailRow(transaction: transaction)
                        Divider()
                            .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.2))
                    
                }
            }
            .padding(.leading, 48)
            .padding(.trailing, 32)
            .background(Color.black)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DummyView: View {
    var body: some View {
        Text("Hello Yi")
    }
}

struct TransactionDetailRow: View {
    let transaction: Transaction
    @EnvironmentObject private var priceModel: SolPriceModel
    
    var body: some View {
        NavigationLink(destination: DummyView()) {
            HStack {
                VStack(alignment: .leading) {
                    Text(transaction.isBuy ? "Buy" : "Sell")
                        .font(.sfRounded(size: .sm, weight: .medium))
                        .foregroundColor(AppColors.lightGray)
                    Text(formatDate(transaction.date))
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundColor(AppColors.gray)
                }
                Spacer()
                
                VStack(alignment: .trailing) {
                    let price = priceModel.formatPrice(usd: transaction.valueUsd, showSign: true)
                    Text(price)
                        .font(.sfRounded(size: .sm, weight: .bold))
                        .foregroundColor(transaction.isBuy ? AppColors.red : AppColors.green)
                    
                    let quantity = priceModel.formatPrice(lamports: abs(transaction.quantityTokens), showUnit: false)
                    Text("\(quantity) \(transaction.symbol)")
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundColor(AppColors.gray)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// Helper function to group transactions
func groupTransactions(_ transactions: [Transaction]) -> [TransactionGroup] {
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
