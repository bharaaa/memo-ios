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
    
    private let repository: AccountRepositoryProtocol
    
    init(repository: AccountRepositoryProtocol) {
        self.repository = repository
    }
    
    func load() {
        // Accounts are ordered by sortOrder by the repository
        accounts = repository.allAccounts()
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
