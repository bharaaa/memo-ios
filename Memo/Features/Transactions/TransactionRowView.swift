//
//  TransactionRowView.swift
//  Memo
//
//  A single transaction row used in HomeView, TransactionListView,
//  and anywhere a compact transaction summary is needed.
//

import SwiftUI

struct TransactionRowView: View {

    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            categoryIcon

            // Middle — name + date
            VStack(alignment: .leading, spacing: 3) {
                Text(rowTitle)
                    .font(.memoBody)
                    .foregroundStyle(.memoPrimaryText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(transaction.date.memoRelativeLabel)
                        .font(.memoCaption)
                        .foregroundStyle(.memoSecondaryText)

                    if let account = transaction.account {
                        Text("·")
                            .foregroundStyle(.memoTertiaryText)
                        Text(account.name)
                            .font(.memoCaption)
                            .foregroundStyle(.memoSecondaryText)
                    }
                }
            }

            Spacer()

            // Amount
            AmountText(
                amount: transaction.amount,
                currencyCode: transaction.currencyCode,
                transactionType: transaction.transactionType,
                size: .small
            )
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private var rowTitle: String {
        if let merchant = transaction.merchant?.name, !merchant.isEmpty { return merchant }
        if !transaction.note.isEmpty { return transaction.note }
        return transaction.category?.name ?? "Transaction"
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(categoryColor.opacity(0.15))
                .frame(width: 44, height: 44)
            Image(systemName: categoryIconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(categoryColor)
        }
    }

    private var categoryColor: Color {
        guard let hex = transaction.category?.colorHex else {
            return transaction.transactionType.color
        }
        return Color(hex: hex)
    }

    private var categoryIconName: String {
        transaction.category?.icon ?? transaction.transactionType.symbol
    }
}

#Preview {
    VStack(spacing: 0) {
        TransactionRowView(transaction: {
            let t = Transaction(amount: 35000, currencyCode: "IDR", note: "Coffee", transactionType: .expense)
            return t
        }())
    }
    .padding(.horizontal, 24)
}
