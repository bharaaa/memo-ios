//
//  TransactionDetailView.swift
//  Memo
//
//  Full detail screen for a transaction, styled like Apple Wallet.
//

import SwiftUI
import SwiftData

@MainActor
struct TransactionDetailView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.dismiss) private var dismiss
    
    let transaction: Transaction
    
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Header
                AmountHeader(transaction: transaction)
                
                // Metadata Section
                MemoryMetadataSection(transaction: transaction)
                    .padding(.horizontal, 16)
                
                // AI Section (Collapsible)
                AISection(transaction: transaction)
                    .padding(.horizontal, 16)
                
                // Notes
                NotesSection(note: transaction.note)
                    .padding(.horizontal, 16)
                
                // Actions
                ActionSection(
                    onEdit: { showEditSheet = true },
                    onDuplicate: duplicateTransaction,
                    onDelete: { showDeleteConfirmation = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Memory Detail")
        .navigationBarTitleDisplayMode(.inline)
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
    
    // MARK: - Actions
    
    private func deleteTransaction() {
        try? appContainer.transactionService.delete(transaction)
        dismiss()
    }
    
    private func duplicateTransaction() {
        try? appContainer.transactionService.duplicate(transaction)
        dismiss()
    }
}
