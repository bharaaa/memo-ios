//
//  TransferViewModel.swift
//  Memo
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class TransferViewModel {
    // MARK: - State
    var amountString: String = ""
    var sourceAccount: Account?
    var destinationAccount: Account?
    var date: Date = Date()
    var note: String = ""
    
    var isSaving = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    private let transactionService: TransactionService
    private let modelContext: ModelContext
    
    // MARK: - Init
    init(transactionService: TransactionService, modelContext: ModelContext) {
        self.transactionService = transactionService
        self.modelContext = modelContext
    }
    
    // MARK: - Actions
    func save() -> Bool {
        let amount = Decimal(string: amountString.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) ?? 0
        guard amount > 0 else {
            errorMessage = "Please enter a valid amount."
            return false
        }
        guard let source = sourceAccount else {
            errorMessage = "Please select a source account."
            return false
        }
        guard let destination = destinationAccount else {
            errorMessage = "Please select a destination account."
            return false
        }
        guard source.id != destination.id else {
            errorMessage = "Source and destination accounts must be different."
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try transactionService.createTransfer(
                amount: amount,
                currencyCode: source.currencyCode,
                from: source,
                to: destination,
                date: date,
                note: note.trimmingCharacters(in: .whitespaces)
            )
            isSaving = false
            return true
        } catch {
            isSaving = false
            errorMessage = "Failed to save transfer: \(error.localizedDescription)"
            return false
        }
    }
}
