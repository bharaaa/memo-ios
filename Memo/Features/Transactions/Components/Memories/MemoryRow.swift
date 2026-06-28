//
//  MemoryRow.swift
//  Memo
//
//  A single transaction row used in the Memories timeline and HomeView.
//  Styled to feel like a native Apple Journal entry or Wallet pass.
//

import SwiftUI

struct MemoryRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 40, height: 40)
                if transaction.isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: transaction.category?.icon ?? transaction.transactionType.symbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if transaction.isProcessing {
                        Text("Organizing details…")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    } else {
                        Text("\(transaction.account?.name ?? "Unknown") • \(relativeDateString(for: transaction.date))")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        
                        if transaction.source == .chat || transaction.source == .ocr {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                        }
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            // Amount
            AmountText(
                money: transaction.originalMoney,
                transactionType: transaction.transactionType,
                size: .small
            )
            .layoutPriority(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
        if transaction.isProcessing {
            return "Just a moment"
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
