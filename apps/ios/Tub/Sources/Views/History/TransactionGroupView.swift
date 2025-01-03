import SwiftUI
import TubAPI

struct TransactionGroup {
    let transactions: [TransactionData]
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
    let transaction: TransactionData
    @EnvironmentObject private var priceModel: SolPriceModel

    var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(transaction.isBuy ? "Buy" : "Sell")
                        .font(.sfRounded(size: .sm, weight: .medium))
                    Text(formatDate(transaction.date))
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                VStack(alignment: .trailing) {
                    Text(priceModel.formatPrice(usd:transaction.valueUsd))
                        .font(.sfRounded(size: .sm, weight: .bold))
                        .foregroundStyle(transaction.isBuy ? Color.red : Color.green)

                    let quantity = priceModel.formatPrice(lamports: abs(transaction.quantityTokens), showUnit: false)
                    Text("\(quantity) \(transaction.symbol)")
                        .font(.sfRounded(size: .xs, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
}


