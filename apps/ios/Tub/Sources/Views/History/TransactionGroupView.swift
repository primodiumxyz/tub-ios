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
    @EnvironmentObject private var priceModel: SolPriceModel

    var body: some View {
        DisclosureGroup {
            ScrollView {
                ForEach(group.transactions, id: \.id) { transaction in
                    TransactionDetailRow(transaction: transaction)
                        .foregroundStyle(.primary)
                    Divider()
                        .background(.secondary)
                }
            }
        } label: {
            HStack(alignment: .center) {
                ImageView(imageUri: group.imageUri, size: 40)
                    .cornerRadius(8)

                VStack(alignment: .leading) {
                    Text(group.symbol)
                        .font(.sfRounded(size: .base, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(formatDate(group.date))
                        .font(.sfRounded(size: .sm, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                let price = priceModel.formatPrice(usd: group.netProfit, showSign: true)
                Text(price)
                    .font(.sfRounded(size: .base, weight: .bold))
                    .foregroundStyle(group.netProfit >= 0 ? Color.green : Color.red)
            }
            .padding(.vertical, 12)
        }
        .accentColor(.primary)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct TransactionDetailRow: View {
    let transaction: Transaction
    @EnvironmentObject private var priceModel: SolPriceModel

    var body: some View {
        NavigationLink(destination: HistoryDetailsView(transaction: transaction)) {
            HStack {
                VStack(alignment: .leading) {
                    Text(transaction.isBuy ? "Buy" : "Sell")
                        .font(.sfRounded(size: .sm, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(formatDate(transaction.date))
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                VStack(alignment: .trailing) {
                    let price = priceModel.formatPrice(usd: transaction.valueUsd, showSign: true)
                    Text(price)
                        .font(.sfRounded(size: .sm, weight: .bold))
                        .foregroundColor(transaction.isBuy ? Color.red : Color.green)

                    let quantity = priceModel.formatPrice(lamports: abs(transaction.quantityTokens), showUnit: false)
                    Text("\(quantity) \(transaction.symbol)")
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(.secondary)
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
