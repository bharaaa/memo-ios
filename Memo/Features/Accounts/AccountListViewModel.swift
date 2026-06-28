//
//  AccountListViewModel.swift
//  Memo
//

import Foundation
import SwiftData
import Observation
import SwiftUI

@MainActor
@Observable
final class AccountListViewModel {
    var accounts: [Account] = []
    var searchText: String = ""
    
    private let repository: AccountRepositoryProtocol
    private let currencyService: CurrencyService
    
    init(repository: AccountRepositoryProtocol, currencyService: CurrencyService = .shared) {
        self.repository = repository
        self.currencyService = currencyService
    }
    
    func load() {
        // Accounts are ordered by sortOrder by the repository
        accounts = repository.allAccounts()
    }
    
    var filteredAccounts: [Account] {
        if searchText.isEmpty {
            return accounts
        }
        let query = searchText.lowercased()
        return accounts.filter {
            $0.name.lowercased().contains(query) ||
            $0.accountType.displayName.lowercased().contains(query) ||
            $0.currencyCode.rawValue.lowercased().contains(query)
        }
    }
    
    var activeCount: Int {
        filteredAccounts.filter { !$0.isArchived }.count
    }
    
    var totalBalance: Money {
        let baseCurrency = currencyService.baseCurrency
        var sum: Decimal = 0
        for account in filteredAccounts {
            if !account.isArchived {
                let convertedIncome = account.transactions
                    .filter { $0.transactionType == .income }
                    .reduce(Decimal(0)) { $0 + $1.convertedMoneyAmount }
                
                let convertedExpense = account.transactions
                    .filter { $0.transactionType == .expense }
                    .reduce(Decimal(0)) { $0 + $1.convertedMoneyAmount }
                    
                sum += account.openingBalanceAmount + convertedIncome - convertedExpense
            }
        }
        return Money(amount: sum, currencyCode: baseCurrency)
    }
    
    func moveAccounts(from source: IndexSet, to destination: Int) {
        var orderedAccounts = accounts
        orderedAccounts.move(fromOffsets: source, toOffset: destination)
        
        for (index, account) in orderedAccounts.enumerated() {
            account.sortOrder = index
            try? repository.save(account)
        }
        
        accounts = orderedAccounts
    }
    
    func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            let account = accounts[index]
            try? repository.delete(account)
        }
        accounts.remove(atOffsets: offsets)
    }
}
