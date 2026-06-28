//
//  TransactionRepository.swift
//  Memo
//
//  Handles all persistence and querying of transactions.
//

import Foundation
import SwiftData

@MainActor
final class TransactionRepository: TransactionRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func save(_ transaction: Transaction) throws {
        transaction.updatedAt = Date()
        context.insert(transaction)
        try context.save()
    }
    
    func delete(_ transaction: Transaction) throws {
        context.delete(transaction)
        try context.save()
    }
    
    func saveTransfer(transfer: Transfer, debit: Transaction, credit: Transaction) throws {
        context.insert(transfer)
        context.insert(debit)
        context.insert(credit)
        try context.save()
    }
    
    // MARK: - Queries
    
    func todaysTransactions() -> [Transaction] {
        let start = Date().startOfDay
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= start },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func recentTransactions(limit: Int = 20) -> [Transaction] {
        var descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func currentMonthTransactions() -> [Transaction] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= startOfMonth },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
