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

    // MARK: - Meta

    let confidence: Double
    let providerName: String

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

        // Resolve category from hint
        self.selectedCategory = categoryService.match(hint: parsed.categoryHint)

        // Load default account
        self.selectedAccount = fetchDefaultAccount()
    }

    // MARK: - Save

    func save(completion: @escaping () -> Void) {
        guard let amountDecimal = parseAmount() else {
            saveError = "Please enter a valid amount."
            return
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
            completion()
        } catch {
            isSaving = false
            saveError = error.localizedDescription
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
