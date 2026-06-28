//
//  TransactionPreviewViewModel.swift
//  Memo
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class TransactionPreviewViewModel {

    // MARK: - Editable Fields

    var amount: String
    var merchantName: String
    var note: String
    var date: Date
    var paymentMethod: PaymentMethod
    var transactionType: TransactionType
    var selectedAccount: Account?
    var selectedCategory: Category?
    var currencyCode: String

    // MARK: - State

    var isSaving = false
    var saveError: String?
    var showAccountPicker = false
    var showCategoryPicker = false
    
    // For tracking if user manually overrode AI
    private(set) var userDidSelectCategory = false
    private(set) var userDidSelectAccount = false

    // MARK: - Meta

    var confidence: Double
    var providerName: String
    var status: ParsingStatus
    
    private var originalParsed: ParsedTransaction

    // MARK: - Dependencies

    private let transactionService: TransactionService
    private let categoryService: CategoryService
    private let modelContext: ModelContext

    // MARK: - Init

    init(
        parsed: ParsedTransaction,
        transactionService: TransactionService,
        categoryService: CategoryService,
        modelContext: ModelContext,
        defaultCurrency: String
    ) {
        self.transactionService = transactionService
        self.categoryService = categoryService
        self.modelContext = modelContext

        self.amount          = parsed.amount?.formatted(currency: parsed.currencyCode ?? defaultCurrency) ?? ""
        self.merchantName    = parsed.merchantName ?? ""
        self.note            = parsed.note ?? ""
        self.date            = parsed.date ?? Date()
        self.paymentMethod   = parsed.paymentMethod ?? .cash
        self.transactionType = parsed.transactionType
        self.currencyCode    = parsed.currencyCode ?? defaultCurrency
        self.confidence      = parsed.confidence
        self.providerName    = parsed.providerName
        self.status          = parsed.status
        self.originalParsed  = parsed

        // Resolve category from hint, fallback to merchant name as a hint
        if let cat = categoryService.match(hint: parsed.categoryHint) {
            self.selectedCategory = cat
        } else {
            self.selectedCategory = categoryService.match(hint: parsed.merchantName)
        }

        // Resolve account from hint or fallback to default
        if let accountHint = parsed.accountHint?.lowercased() {
            let descriptor = FetchDescriptor<Account>(
                predicate: #Predicate { $0.isArchived == false }
            )
            if let accounts = try? modelContext.fetch(descriptor),
               let matchedAccount = accounts.first(where: { $0.name.lowercased().contains(accountHint) }) {
                self.selectedAccount = matchedAccount
            } else {
                self.selectedAccount = fetchDefaultAccount()
            }
        } else {
            self.selectedAccount = fetchDefaultAccount()
        }
    }

    // MARK: - Dynamic Updates
    
    func update(with newParsed: ParsedTransaction) {
        // Merchant
        if merchantName == (originalParsed.merchantName ?? "") && newParsed.merchantName != nil {
            merchantName = newParsed.merchantName!
        }
        
        // Note
        if note == (originalParsed.note ?? "") && newParsed.note != nil {
            note = newParsed.note!
        }
        
        // Category
        if !userDidSelectCategory {
            if let hint = newParsed.categoryHint, let cat = categoryService.match(hint: hint) {
                selectedCategory = cat
            } else if let merchant = newParsed.merchantName, let cat = categoryService.match(hint: merchant) {
                selectedCategory = cat
            }
        }
        
        // Account
        if !userDidSelectAccount {
            if let hint = newParsed.accountHint?.lowercased() {
                let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.isArchived == false })
                if let accounts = try? modelContext.fetch(descriptor),
                   let matched = accounts.first(where: { $0.name.lowercased().contains(hint) }) {
                    selectedAccount = matched
                }
            }
        }
        
        self.confidence = newParsed.confidence
        self.providerName = newParsed.providerName
        self.status = newParsed.status
        self.originalParsed = newParsed
    }

    // MARK: - Manual Selections
    
    func userSelected(category: Category) {
        selectedCategory = category
        userDidSelectCategory = true
    }
    
    func userSelected(account: Account) {
        selectedAccount = account
        userDidSelectAccount = true
    }

    @discardableResult
    func save(completion: @escaping (Transaction?) -> Void) -> Transaction? {
        guard let amountDecimal = parseAmount() else {
            saveError = "Please enter a valid amount."
            return nil
        }

        isSaving = true
        saveError = nil

        let parsed = ParsedTransaction(
            amount: amountDecimal,
            currencyCode: currencyCode,
            merchantName: merchantName.isEmpty ? nil : merchantName,
            note: note.isEmpty ? nil : note,
            date: date,
            paymentMethod: paymentMethod,
            transactionType: transactionType,
            confidence: 1.0, // user confirmed
            rawInput: "",
            providerName: "user_confirmed"
        )

        do {
            let transaction = try transactionService.save(
                parsed: parsed,
                account: selectedAccount,
                preferredCurrency: currencyCode
            )
            // Apply user-selected category directly
            if let cat = selectedCategory {
                transaction.category = cat
                try transactionService.update(transaction)
            }
            
            isSaving = false
            completion(transaction)
            return transaction
        } catch {
            isSaving = false
            saveError = error.localizedDescription
            return nil
        }
    }

    // MARK: - Helpers

    private func parseAmount() -> Decimal? {
        // Try to parse the display string back — handle "Rp 45.000", "45000", "45k"
        let stripped = amount
            .components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".,km")).inverted)
            .joined()
        return Decimal.parse(stripped)
    }

    private func fetchDefaultAccount() -> Account? {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isDefault == true && $0.isArchived == false }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func allAccounts() -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
