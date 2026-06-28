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
    
    func currentBalance(for account: Account) -> Money {
        return account.currentBalance
    }
    
    func totalIncome(for account: Account) -> Money {
        let amount = account.transactions
            .filter { $0.transactionType == .income }
            .reduce(Decimal(0)) { $0 + $1.originalMoneyAmount }
        return Money(amount: amount, currencyCode: account.currencyCode)
    }
    
    func totalExpenses(for account: Account) -> Money {
        let amount = account.transactions
            .filter { $0.transactionType == .expense }
            .reduce(Decimal(0)) { $0 + $1.originalMoneyAmount }
        return Money(amount: amount, currencyCode: account.currencyCode)
    }
    
    func transferIn(for account: Account) -> Money {
        // A transfer-in is an .income transaction that is linked to a transfer
        let amount = account.transactions
            .filter { $0.transactionType == .income && $0.linkedTransferID != nil }
            .reduce(Decimal(0)) { $0 + $1.originalMoneyAmount }
        return Money(amount: amount, currencyCode: account.currencyCode)
    }
    
    func transferOut(for account: Account) -> Money {
        // A transfer-out is an .expense transaction that is linked to a transfer
        let amount = account.transactions
            .filter { $0.transactionType == .expense && $0.linkedTransferID != nil }
            .reduce(Decimal(0)) { $0 + $1.originalMoneyAmount }
        return Money(amount: amount, currencyCode: account.currencyCode)
    }
    
    func transactionCount(for account: Account) -> Int {
        return account.transactions.count
    }
    
    func totalAssets(in currency: CurrencyCode) -> Money {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isArchived == false }
        )
        let accounts = (try? context.fetch(descriptor)) ?? []
        
        // Sum all converted transactions
        var sum: Decimal = 0
        for account in accounts {
            // Note: openingBalance isn't auto-converted. In a true implementation, 
            // we'd either convert it here dynamically, or sum only `convertedMoneyAmount` from transactions
            // For now, we sum converted transactions.
            let convertedIncome = account.transactions
                .filter { $0.transactionType == .income }
                .reduce(Decimal(0)) { $0 + $1.convertedMoneyAmount }
            
            let convertedExpense = account.transactions
                .filter { $0.transactionType == .expense }
                .reduce(Decimal(0)) { $0 + $1.convertedMoneyAmount }
                
            // HACK: for this example, we assume opening balance was converted or 1:1 if migration
            sum += account.openingBalanceAmount + convertedIncome - convertedExpense
        }
        
        return Money(amount: sum, currencyCode: currency)
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
