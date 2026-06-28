import SwiftUI

struct RecentMemoriesSection: View {
    let transactions: [Transaction]
    let onEmptyAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Memories")
                    .font(.memoCaption)
                    .foregroundStyle(.memoTertiaryText)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                NavigationLink(value: "SeeAll") {
                    Text("See All")
                        .font(.memoCaption)
                        .foregroundStyle(.memoPrimary)
                }
            }
            .memoScreenPadding()
            
            if transactions.isEmpty {
                EmptyState(
                    icon: "sparkles",
                    title: "Nothing remembered yet.",
                    message: "Start by typing an expense or importing a receipt.",
                    action: onEmptyAction,
                    actionLabel: "Add first memory"
                )
                .padding(.top, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(transactions) { transaction in
                        NavigationLink(value: transaction) {
                            MemoryRowView(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                        
                        if transaction != transactions.last {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
                .memoCardStyle()
                .memoScreenPadding()
            }
        }
        .padding(.top, 16)
    }
}

struct MemoryRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.category?.icon ?? transaction.transactionType.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(categoryColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.memoHeadline)
                    .foregroundStyle(.memoPrimaryText)
                    .lineLimit(1)
                
                Text("\(transaction.account?.name ?? "Unknown") • \(relativeDateString(for: transaction.date))")
                    .font(.memoCaption)
                    .foregroundStyle(.memoTertiaryText)
            }
            
            Spacer()
            
            AmountText(
                amount: transaction.amount,
                currencyCode: transaction.currencyCode,
                transactionType: transaction.transactionType,
                size: .small
            )
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.memoTertiaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    // MARK: - Helpers
    
    private var titleText: String {
        if let merchant = transaction.merchant?.name, !merchant.isEmpty {
            return merchant
        }
        if !transaction.note.isEmpty {
            return transaction.note
        }
        return transaction.category?.name ?? "Transaction"
    }
    
    private var categoryColor: Color {
        guard let hex = transaction.category?.colorHex else {
            switch transaction.transactionType {
            case .expense: return .memoExpense
            case .income: return .memoIncome
            case .transfer: return .memoPrimary
            }
        }
        return Color(hex: hex)
    }
    
    private func relativeDateString(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
