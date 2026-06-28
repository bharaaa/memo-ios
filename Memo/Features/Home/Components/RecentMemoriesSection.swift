//
//  RecentMemoriesSection.swift
//  Memo
//
//  Displays a native Apple-style list of recent transactions.
//

import SwiftUI

struct RecentMemoriesSection: View {
    let transactions: [Transaction]
    let onEmptyAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT MEMORIES")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)
                Spacer()
                NavigationLink(value: "SeeAll") {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(Color.memoPrimary)
                }
            }
            .memoScreenPadding()
            
            if transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.secondary)
                    
                    Text("Nothing remembered yet.")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    
                    Text("Try typing an expense above")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(transactions) { transaction in
                        NavigationLink(value: transaction) {
                            MemoryRowView(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                        
                        if transaction != transactions.last {
                            Divider()
                                .padding(.leading, 64) // Aligns with the text, skipping the icon
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .memoScreenPadding()
            }
        }
        .padding(.bottom, 32)
    }
}

struct MemoryRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 36, height: 36)
                
                Image(systemName: transaction.category?.icon ?? transaction.transactionType.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                
                Text("\(transaction.account?.name ?? "Unknown") • \(relativeDateString(for: transaction.date))")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer(minLength: 8)
            
            AmountText(
                amount: transaction.amount,
                currencyCode: transaction.currencyCode,
                transactionType: transaction.transactionType,
                size: .small
            )
            .layoutPriority(1) // Ensure amount doesn't truncate before text does
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(UIColor.tertiaryLabel))
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
