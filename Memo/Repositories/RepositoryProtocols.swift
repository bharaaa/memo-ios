//
//  RepositoryProtocols.swift
//  Memo
//
//  Defines the contracts for data access, ensuring dependency inversion
//  and testability across the app.
//

import Foundation

@MainActor
protocol AccountRepositoryProtocol {
    func currentBalance(for account: Account) -> Decimal
    func totalIncome(for account: Account) -> Decimal
    func totalExpenses(for account: Account) -> Decimal
    func transferIn(for account: Account) -> Decimal
    func transferOut(for account: Account) -> Decimal
    func transactionCount(for account: Account) -> Int
    func totalAssets() -> Decimal
    func recentTransactions(for account: Account, limit: Int) -> [Transaction]
    
    // Additional CRUD operations that should belong in the repository
    func allAccounts() -> [Account]
    func defaultAccount() -> Account?
    func account(byName name: String) -> Account?
    func save(_ account: Account) throws
    func delete(_ account: Account) throws
}

@MainActor
protocol TransactionRepositoryProtocol {
    func save(_ transaction: Transaction) throws
    func delete(_ transaction: Transaction) throws
    func todaysTransactions() -> [Transaction]
    func recentTransactions(limit: Int) -> [Transaction]
    func currentMonthTransactions() -> [Transaction]
    
    // Transfer logic should use the repository to persist
    func saveTransfer(transfer: Transfer, debit: Transaction, credit: Transaction) throws
}

@MainActor
protocol CategoryRepositoryProtocol {
    func allCategories(type: TransactionType) -> [Category]
    func category(byName name: String) -> Category?
    func defaultCategory(for type: TransactionType) -> Category?
    func save(_ category: Category) throws
    func delete(_ category: Category) throws
}
