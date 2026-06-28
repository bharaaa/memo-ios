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
    var currencyCode: CurrencyCode

    // MARK: - State

    var isSaving = false
    var saveError: String?
    var showAccountPicker = false
    var showCategoryPicker = false
    
    // For tracking if user manually overrode AI
    private(set) var userDidSelectCategory = false
    private(set) var userDidSelectAccount = false
    private(set) var userDidSelectPaymentMethod = false

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
        defaultCurrency: CurrencyCode
    ) {
        self.transactionService = transactionService
        self.categoryService = categoryService
        self.modelContext = modelContext

        
        let cCode = CurrencyCode(rawValue: parsed.currencyCode ?? "") ?? defaultCurrency
        self.currencyCode = cCode
        
        if let amt = parsed.amount {
            let m = Money(amount: amt, currencyCode: cCode)
            self.amount = MoneyFormatter.format(m, locale: LanguageManager.shared.currentLocale, showSign: false)
        } else {
            self.amount = ""
        }
        
        self.merchantName    = parsed.merchantName ?? ""
        self.note            = parsed.note ?? ""
        self.date            = parsed.date ?? Date()
        self.paymentMethod   = parsed.paymentMethod ?? .cash
        self.transactionType = parsed.transactionType
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
        
        // Payment Method
        if !userDidSelectPaymentMethod {
            if let pm = newParsed.paymentMethod {
                paymentMethod = pm
            }
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
    
    func userSelected(paymentMethod: PaymentMethod) {
        self.paymentMethod = paymentMethod
        userDidSelectPaymentMethod = true
    }

    func save(completion: @escaping (Transaction?) -> Void) {
        guard let amountDecimal = parseAmount() else {
            saveError = "Please enter a valid amount."
            completion(nil)
            return
        }

        isSaving = true
        saveError = nil

        var parsed = ParsedTransaction(
            amount: amountDecimal,
            currencyCode: currencyCode.rawValue,
            merchantName: merchantName.isEmpty ? nil : merchantName,
            note: note.isEmpty ? nil : note,
            date: date,
            paymentMethod: paymentMethod,
            transactionType: transactionType,
            confidence: 1.0, // user confirmed
            rawInput: "",
            providerName: "user_confirmed"
        )
        
        // Let the repository know it should be created with isProcessing=true
        // if we are still waiting for LLM results.
        let processing = (status == .parsing)

        Task {
            do {
                let transaction = try await transactionService.save(
                    parsed: parsed,
                    account: selectedAccount
                )
                
                // Apply user-selected category directly
                if let cat = selectedCategory {
                    transaction.category = cat
                }
                
                if processing {
                    transaction.isProcessing = true
                }
                
                try await transactionService.update(transaction)
                
                await MainActor.run {
                    isSaving = false
                    completion(transaction)
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                    completion(nil)
                }
            }
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
