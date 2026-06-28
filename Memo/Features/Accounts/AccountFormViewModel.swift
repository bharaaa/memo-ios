//
//  AccountFormViewModel.swift
//  Memo
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class AccountFormViewModel {
    
    // MARK: - State
    
    var name: String
    var icon: String
    var colorHex: String
    var currencyCode: String
    var accountType: AccountType
    var openingBalanceString: String
    var isArchived: Bool
    
    var isSaving = false
    var errorMessage: String?
    
    var showIconPicker = false
    var showColorPicker = false
    var showCurrencyPicker = false
    var showDeleteConfirmation = false
    
    let isEditing: Bool
    let existingAccount: Account?
    private let modelContext: ModelContext
    
    // MARK: - Init
    
    init(account: Account? = nil, modelContext: ModelContext, defaultCurrency: String = "IDR") {
        self.modelContext = modelContext
        self.existingAccount = account
        self.isEditing = account != nil
        
        self.name = account?.name ?? ""
        self.icon = account?.icon ?? "creditcard.fill"
        self.colorHex = account?.colorHex ?? "#3B82F6"
        self.currencyCode = account?.currencyCode ?? defaultCurrency
        self.accountType = account?.accountType ?? .bank
        self.isArchived = account?.isArchived ?? false
        
        if let openingBalance = account?.openingBalance {
            self.openingBalanceString = "\(openingBalance)"
        } else {
            self.openingBalanceString = "0"
        }
    }
    
    // MARK: - Actions
    
    func save() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter an account name."
            return false
        }
        
        let openingBalance = Decimal(string: openingBalanceString.replacingOccurrences(of: ",", with: "")) ?? 0
        
        isSaving = true
        errorMessage = nil
        
        if let account = existingAccount {
            // Update
            account.name = trimmedName
            account.icon = icon
            account.colorHex = colorHex
            account.currencyCode = currencyCode
            account.accountType = accountType
            account.openingBalance = openingBalance
            account.isArchived = isArchived
        } else {
            // Create
            let newAccount = Account(
                name: trimmedName,
                icon: icon,
                colorHex: colorHex,
                currencyCode: currencyCode,
                accountType: accountType,
                isDefault: false
            )
            newAccount.openingBalance = openingBalance
            modelContext.insert(newAccount)
        }
        
        do {
            try modelContext.save()
            isSaving = false
            return true
        } catch {
            isSaving = false
            errorMessage = "Failed to save: \(error.localizedDescription)"
            return false
        }
    }
    
    func delete() -> Bool {
        guard let account = existingAccount else { return true }
        
        // Don't delete if it's the last default account, maybe add checks later.
        // SwiftData cascade will handle transactions if relationship is set, 
        // but currently we use default nullify, so transactions might lose their account.
        
        modelContext.delete(account)
        do {
            try modelContext.save()
            return true
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            return false
        }
    }
}
