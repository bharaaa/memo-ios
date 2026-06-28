//
//  MemoryDetailComponents.swift
//  Memo
//
//  Reusable components for the Memory Detail screen, styled after Apple Wallet.
//

import SwiftUI

// MARK: - Hero Header

struct AmountHeader: View {
    @Environment(\.locale) private var locale
    let transaction: Transaction
    
    var body: some View {
        VStack(spacing: 8) {
            AmountText(
                amount: transaction.amount,
                currencyCode: transaction.currencyCode,
                transactionType: transaction.transactionType,
                size: .large
            )
            .padding(.top, 16)
            
            VStack(spacing: 4) {
                if let merchant = transaction.merchant?.name, !merchant.isEmpty {
                    Text(merchant)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                } else if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                }
                
                Text(transaction.category?.name ?? "Transaction")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                
                let dateStyle = Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale)
                let timeStyle = Date.FormatStyle(date: .omitted, time: .shortened, locale: locale)
                
                let dateStr = transaction.date.formatted(dateStyle)
                let timeStr = transaction.date.formatted(timeStyle)
                Text("\(dateStr) • \(timeStr)")
                    .font(.caption)
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
    }
}

// MARK: - Generic Detail Row

struct DetailRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let value: String
    var isLast: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon block
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                Text(value)
                    .font(.body)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
            if !isLast {
                Divider()
                    .padding(.leading, 64)
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}

// MARK: - Metadata Section

struct MemoryMetadataSection: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(spacing: 0) {
            let catName = transaction.category?.name ?? "None"
            let catIcon = transaction.category?.icon ?? transaction.transactionType.symbol
            DetailRow(title: "Category", icon: catIcon, iconColor: categoryColor, value: catName)
            
            let accName = transaction.account?.name ?? "None"
            let accIcon = transaction.account?.icon ?? "creditcard"
            let accColor = transaction.account != nil ? Color(hex: transaction.account!.colorHex) : Color.memoPrimary
            DetailRow(title: "Account", icon: accIcon, iconColor: accColor, value: accName)
            
            DetailRow(title: "Payment", icon: "banknote", iconColor: Color.memoIncome, value: transaction.paymentMethod.displayName, isLast: true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
}

// MARK: - AI Section

struct AISection: View {
    let transaction: Transaction
    @State private var isExpanded = false
    
    var body: some View {
        if transaction.source == .chat || transaction.source == .ocr {
            VStack(spacing: 0) {
                // Header (Tappable)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.purple)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        Text("AI Parsed")
                            .font(.body)
                            .foregroundStyle(Color.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(UIColor.tertiaryLabel))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Content
                if isExpanded {
                    Divider().padding(.leading, 64)
                    
                    HStack {
                        Text("Source")
                            .font(.body)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(transaction.source.displayName)
                            .font(.body)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .padding(.leading, 48) // Indented
                    
                    Divider().padding(.leading, 64)
                    
                    HStack {
                        Text("Confidence")
                            .font(.body)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(String(format: "%.0f%%", transaction.confidence * 100))
                            .font(.body)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .padding(.leading, 48) // Indented
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Notes Section

struct NotesSection: View {
    let note: String
    
    var body: some View {
        if !note.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("NOTES")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, 16)
                
                Text(note)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

// MARK: - Action Section

struct ActionSection: View {
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onEdit) {
                Text("Edit Memory")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .foregroundStyle(Color.memoPrimary)
            }
            
            Divider().padding(.leading, 16)
            
            Button(action: onDuplicate) {
                Text("Duplicate")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .foregroundStyle(Color.primary)
            }
            
            Divider().padding(.leading, 16)
            
            Button(action: onDelete) {
                Text("Delete")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .foregroundStyle(Color.red)
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
