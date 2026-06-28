//
//  TransactionDetailView.swift
//  Memo
//
//  Full detail screen for a transaction.
//  Accessed by tapping a transaction in the history list or home screen.
//

import SwiftUI
import SwiftData

@MainActor
struct TransactionDetailView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let transaction: Transaction
    
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header (Amount & Merchant)
                VStack(spacing: 8) {
                    AmountText(
                        amount: transaction.amount,
                        currencyCode: transaction.currencyCode,
                        transactionType: transaction.transactionType,
                        size: .large
                    )
                    
                    if let merchant = transaction.merchant?.name, !merchant.isEmpty {
                        Text(merchant)
                            .font(.memoHeadline)
                            .foregroundStyle(.memoPrimaryText)
                    } else if !transaction.note.isEmpty {
                        Text(transaction.note)
                            .font(.memoHeadline)
                            .foregroundStyle(.memoPrimaryText)
                    } else {
                        Text(transaction.category?.name ?? "Transaction")
                            .font(.memoHeadline)
                            .foregroundStyle(.memoPrimaryText)
                    }
                }
                .padding(.top, 24)
                
                // Info Cards
                VStack(spacing: 16) {
                    // Category & Account
                    HStack(spacing: 12) {
                        DetailCard(
                            title: "Category",
                            icon: transaction.category?.icon ?? transaction.transactionType.symbol,
                            iconColor: categoryColor,
                            value: transaction.category?.name ?? "None"
                        )
                        
                        DetailCard(
                            title: "Account",
                            icon: transaction.account?.icon ?? "creditcard",
                            iconColor: transaction.account.map { Color(hex: $0.colorHex) } ?? .memoPrimary,
                            value: transaction.account?.name ?? "None"
                        )
                    }
                    
                    // Date & Payment
                    HStack(spacing: 12) {
                        DetailCard(
                            title: "Date",
                            icon: "calendar",
                            iconColor: .memoAccent,
                            value: transaction.date.formatted(date: .abbreviated, time: .shortened)
                        )
                        
                        DetailCard(
                            title: "Payment",
                            icon: "banknote",
                            iconColor: .memoIncome,
                            value: transaction.paymentMethod.displayName
                        )
                    }
                }
                .padding(.horizontal, 16)
                
                // Notes & Metadata
                VStack(spacing: 0) {
                    if !transaction.note.isEmpty && transaction.merchant?.name != nil {
                        infoRow(title: "Note", value: transaction.note)
                        Divider().padding(.leading, 16)
                    }
                    
                    infoRow(title: "Source", value: transaction.source.displayName)
                    Divider().padding(.leading, 16)
                    
                    infoRow(
                        title: "Confidence", 
                        value: String(format: "%.0f%%", transaction.confidence * 100)
                    )
                }
                .background(Color.memoCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Text("Edit Memory")
                            .font(.memoHeadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.memoCard)
                            .foregroundStyle(.memoPrimaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    Button {
                        duplicateTransaction()
                    } label: {
                        Text("Duplicate")
                            .font(.memoHeadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.memoCard)
                            .foregroundStyle(.memoPrimaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color.memoBackground)
        .navigationTitle("Memory Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.memoExpense)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            TransactionEditView(transaction: transaction)
                .environment(appContainer)
        }
        .confirmationDialog(
            "Delete Memory?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteTransaction()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Helpers
    
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
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.memoSecondaryText)
                .font(.memoBody)
            Spacer()
            Text(value)
                .foregroundStyle(.memoPrimaryText)
                .font(.memoBody)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func deleteTransaction() {
        try? appContainer.transactionService.delete(transaction)
        dismiss()
    }
    
    private func duplicateTransaction() {
        try? appContainer.transactionService.duplicate(transaction)
        dismiss()
    }
}

fileprivate struct DetailCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.subheadline)
                Text(title)
                    .font(.memoCaption)
                    .foregroundStyle(.memoSecondaryText)
            }
            Text(value)
                .font(.memoHeadline)
                .foregroundStyle(.memoPrimaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.memoCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
