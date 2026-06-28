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
    
    init(repository: AccountRepositoryProtocol) {
        self.repository = repository
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
            $0.currencyCode.lowercased().contains(query)
        }
    }
    
    var activeCount: Int {
        filteredAccounts.filter { !$0.isArchived }.count
    }
    
    var totalBalance: Decimal {
        filteredAccounts.filter { !$0.isArchived }.reduce(0) { $0 + $1.currentBalance }
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
