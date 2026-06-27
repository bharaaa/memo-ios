//
//  TransactionService.swift
//  Memo
//
//  The only class that writes Transaction objects to SwiftData.
//  AI providers never write here directly — everything goes through
//  validate() → save(). This enforces the pipeline contract.
//

import Foundation
import SwiftData

@MainActor
final class TransactionService {

    private let context: ModelContext
    private let categoryService: CategoryService

    init(context: ModelContext) {
        self.context = context
        self.categoryService = CategoryService(context: context)
    }

    // MARK: - Validation

    enum ValidationError: LocalizedError {
        case missingAmount
        case negativeAmount
        case missingAccount
        case missingDate

        var errorDescription: String? {
            switch self {
            case .missingAmount:   return "Please enter an amount."
            case .negativeAmount:  return "Amount must be greater than zero."
            case .missingAccount:  return "Please select an account."
            case .missingDate:     return "Please select a date."
            }
        }
    }

    func validate(_ parsed: ParsedTransaction) throws {
        guard let amount = parsed.amount else { throw ValidationError.missingAmount }
        guard amount > 0 else { throw ValidationError.negativeAmount }
    }

    // MARK: - Save from ParsedTransaction

    /// Converts a validated ParsedTransaction into a Transaction and persists it.
    /// - Parameters:
    ///   - parsed: The validated AI result
    ///   - account: The account to associate (defaults to the first default account)
    ///   - preferredCurrency: Fallback currency if the AI didn't detect one
    @discardableResult
    func save(
        parsed: ParsedTransaction,
        account: Account?,
        preferredCurrency: String
    ) throws -> Transaction {
        try validate(parsed)

        let currency = parsed.currencyCode ?? preferredCurrency
        let resolvedAccount = account ?? fetchDefaultAccount()

        let transaction = Transaction(
            amount: parsed.amount!,
            currencyCode: currency,
            note: parsed.note ?? "",
            date: parsed.date ?? Date(),
            paymentMethod: parsed.paymentMethod ?? .cash,
            transactionType: parsed.transactionType,
            source: .chat,
            confidence: parsed.confidence,
            isConfirmed: true
        )

        transaction.account = resolvedAccount

        // Resolve category from hint
        if let hint = parsed.categoryHint {
            transaction.category = categoryService.match(hint: hint)
        }

        // Find or create merchant
        if let merchantName = parsed.merchantName, !merchantName.isEmpty {
            transaction.merchant = findOrCreateMerchant(
                named: merchantName,
                suggestedCategory: transaction.category
            )
        }

        context.insert(transaction)
        try context.save()

        return transaction
    }

    // MARK: - Direct Save

    /// Saves an already-constructed Transaction (from the preview/edit screen).
    func save(_ transaction: Transaction) throws {
        transaction.updatedAt = Date()
        context.insert(transaction)
        try context.save()
    }

    // MARK: - Delete

    func delete(_ transaction: Transaction) throws {
        context.delete(transaction)
        try context.save()
    }

    // MARK: - Update

    func update(_ transaction: Transaction) throws {
        transaction.updatedAt = Date()
        try context.save()
    }

    // MARK: - Queries

    func todaysTransactions() -> [Transaction] {
        let start = Date().startOfDay
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= start },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func recentTransactions(limit: Int = 20) -> [Transaction] {
        var descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Helpers

    private func fetchDefaultAccount() -> Account? {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isDefault == true && $0.isArchived == false }
        )
        return try? context.fetch(descriptor).first
    }

    private func findOrCreateMerchant(named name: String, suggestedCategory: Category?) -> Merchant {
        let normalised = name.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<Merchant>(
            predicate: #Predicate { $0.normalizedName == normalised }
        )
        if let existing = try? context.fetch(descriptor).first {
            // Update default category if we now have a better suggestion
            if existing.defaultCategory == nil, let cat = suggestedCategory {
                existing.defaultCategory = cat
            }
            return existing
        }

        let merchant = Merchant(name: name.capitalized, defaultCategory: suggestedCategory)
        context.insert(merchant)
        return merchant
    }
}
