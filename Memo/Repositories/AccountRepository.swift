//
//  AccountRepository.swift
//  Memo
//
//  Encapsulates all account balance logic and calculations.
//  Balances are always derived from transactions on-the-fly.
//

import Foundation
import SwiftData

@MainActor
final class AccountRepository: AccountRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Core Calculations
    
    func currentBalance(for account: Account) -> Decimal {
        return account.currentBalance
    }
    
    func totalIncome(for account: Account) -> Decimal {
        account.transactions
            .filter { $0.transactionType == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    func totalExpenses(for account: Account) -> Decimal {
        account.transactions
            .filter { $0.transactionType == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    func transferIn(for account: Account) -> Decimal {
        // A transfer-in is an .income transaction that is linked to a transfer
        account.transactions
            .filter { $0.transactionType == .income && $0.linkedTransferID != nil }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    func transferOut(for account: Account) -> Decimal {
        // A transfer-out is an .expense transaction that is linked to a transfer
        account.transactions
            .filter { $0.transactionType == .expense && $0.linkedTransferID != nil }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    func transactionCount(for account: Account) -> Int {
        return account.transactions.count
    }
    
    func totalAssets() -> Decimal {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isArchived == false }
        )
        let accounts = (try? context.fetch(descriptor)) ?? []
        return accounts.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }
    
    func recentTransactions(for account: Account, limit: Int = 20) -> [Transaction] {
        return Array(
            account.transactions
                .sorted(by: { $0.date > $1.date })
                .prefix(limit)
        )
    }
    
    // MARK: - CRUD
    
    func allAccounts() -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func defaultAccount() -> Account? {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isDefault == true && $0.isArchived == false }
        )
        return try? context.fetch(descriptor).first
    }
    
    func account(byName name: String) -> Account? {
        let normalised = name.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isArchived == false }
        )
        if let accounts = try? context.fetch(descriptor) {
            return accounts.first { $0.name.lowercased() == normalised }
        }
        return nil
    }
    
    func save(_ account: Account) throws {
        context.insert(account)
        try context.save()
    }
    
    func delete(_ account: Account) throws {
        context.delete(account)
        try context.save()
    }
}
